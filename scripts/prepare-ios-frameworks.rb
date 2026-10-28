#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

# Build only from Google's pinned archives. The simulator compatibility approach
# is documented at https://github.com/d-date/google-mlkit-swiftpm/issues/112.
# Patching archive members in place is essential: MLKitCommon contains duplicate
# member names, so extracting and repacking it can corrupt its symbol table.
module DigitalInkFrameworks
  ROOT = File.expand_path('..', __dir__)
  AR_MAGIC = "!<arch>\n".b

  def self.run(*args)
    output, status = Open3.capture2e({ 'ZERO_AR_DATE' => '1' }, *args)
    raise "#{args.join(' ')} failed:\n#{output}" unless status.success?
    output
  end

  def self.patch_object!(data, start, limit)
    return 0 unless data.byteslice(start, 4) == [0xfeedfacf].pack('V')
    raise 'Expected an arm64 Mach-O object' unless data.byteslice(start + 4, 4).unpack1('V') == 0x100000c
    raise 'Expected MH_OBJECT' unless data.byteslice(start + 12, 4).unpack1('V') == 1

    count, size = data.byteslice(start + 16, 8).unpack('VV')
    offset = start + 32
    boundary = offset + size
    raise 'Truncated Mach-O commands' if boundary > limit
    patched = 0
    count.times do
      raise 'Truncated Mach-O command' if offset + 8 > boundary
      command, length = data.byteslice(offset, 8).unpack('VV')
      raise 'Invalid Mach-O command' if length < 8 || offset + length > boundary
      if command == 0x32 # LC_BUILD_VERSION
        raise 'Invalid LC_BUILD_VERSION' if length < 24
        platform = data.byteslice(offset + 8, 4).unpack1('V')
        raise "Unexpected source platform #{platform}" unless platform == 2
        data[offset + 8, 4] = [7].pack('V') # PLATFORM_IOSSIMULATOR
        patched += 1
      end
      offset += length
    end
    raise 'Object has no LC_BUILD_VERSION; upstream packaging changed' if patched.zero?
    patched
  end

  def self.patch_simulator!(path)
    data = File.binread(path)
    patched = 0
    if data.start_with?(AR_MAGIC)
      offset = AR_MAGIC.bytesize
      while offset < data.bytesize
        header = data.byteslice(offset, 60)
        raise 'Truncated archive header' unless header && header.bytesize == 60 && header.end_with?("`\n")
        size = Integer(header.byteslice(48, 10).strip, 10)
        payload = offset + 60
        finish = payload + size
        raise 'Truncated archive member' if finish > data.bytesize
        name = header.byteslice(0, 16).strip
        payload += Integer(name.delete_prefix('#1/'), 10) if name.start_with?('#1/')
        raise 'Invalid archive member name' if payload > finish
        patched += patch_object!(data, payload, finish)
        offset = finish + (finish.odd? ? 1 : 0)
      end
    else
      patched = patch_object!(data, 0, data.bytesize)
    end
    raise 'No iOS platform commands found' if patched.zero?
    File.binwrite(path, data)
    patched
  end

  # Bare MH_OBJECT frameworks must become static archives. Otherwise CocoaPods
  # may treat them as dynamic frameworks and try to embed or relink them.
  def self.make_static!(path)
    return if File.binread(path, 8) == AR_MAGIC
    raise "Not a Mach-O object: #{path}" unless File.binread(path, 4) == [0xfeedfacf].pack('V')
    object = "#{path}.o"
    FileUtils.mv(path, object)
    run('xcrun', 'ar', 'crs', path, object)
    FileUtils.rm(object)
  end

  def self.prepare
    manifest_path = File.join(__dir__, 'mlkit-binaries.json')
    manifest = JSON.parse(File.read(manifest_path))
    cache = File.join(ROOT, '.cache', 'mlkit')
    FileUtils.mkdir_p(cache)

    Dir.mktmpdir('digital-ink-frameworks-') do |work|
      generated = File.join(work, 'generated')
      %w[Frameworks Resources Notices].each { |dir| FileUtils.mkdir_p(File.join(generated, dir)) }

      manifest.each do |name, source|
        puts "Preparing #{name} #{source.fetch('version')}"
        archive = File.join(cache, "#{name}-#{source.fetch('version')}.tar.gz")
        unless File.file?(archive) && Digest::SHA256.file(archive).hexdigest == source.fetch('sha256')
          partial = "#{archive}.download"
          run('curl', '--fail', '--location', '--retry', '3', '--output', partial, source.fetch('url'))
          raise "SHA-256 mismatch for #{name}" unless Digest::SHA256.file(partial).hexdigest == source.fetch('sha256')
          FileUtils.mv(partial, archive)
        end

        extracted = File.join(work, name)
        FileUtils.mkdir_p(extracted)
        run('tar', '-xzf', archive, '-C', extracted)
        original = File.join(extracted, 'Frameworks', "#{name}.framework")
        binary = File.join(original, name)
        device = File.join(work, 'device', "#{name}.framework")
        simulator = File.join(work, 'simulator', "#{name}.framework")
        [device, simulator].each do |framework|
          FileUtils.mkdir_p(File.dirname(framework))
          FileUtils.cp_r(original, framework)
          # Static framework resources belong in the app, not in an embedded
          # framework. CocoaPods copies Resources/ via resource_bundles.
          Dir.glob(File.join(framework, '*.bundle')).each { |bundle| FileUtils.rm_rf(bundle) }
          FileUtils.rm_f(File.join(framework, 'PrivacyInfo.xcprivacy'))
        end

        arm64 = File.join(work, "#{name}-arm64")
        intel = File.join(work, "#{name}-x86_64")
        run('xcrun', 'lipo', binary, '-thin', 'arm64', '-output', File.join(device, name))
        run('xcrun', 'lipo', binary, '-thin', 'arm64', '-output', arm64)
        run('xcrun', 'lipo', binary, '-thin', 'x86_64', '-output', intel)
        count = patch_simulator!(arm64)
        [File.join(device, name), arm64, intel].each { |path| make_static!(path) }
        run('xcrun', 'lipo', '-create', arm64, intel, '-output', File.join(simulator, name))
        run('xcodebuild', '-create-xcframework', '-framework', device, '-framework', simulator,
            '-output', File.join(generated, 'Frameworks', "#{name}.xcframework"))

        notices = File.join(generated, 'Notices', name)
        FileUtils.mkdir_p(notices)
        %w[NOTICES LICENSE README.md].each do |file|
          path = File.join(extracted, file)
          FileUtils.cp(path, notices) if File.file?(path)
        end
        resources = File.join(extracted, 'Resources')
        FileUtils.cp_r(Dir.glob(File.join(resources, '*')), File.join(generated, 'Resources')) if File.directory?(resources)
        privacy = File.join(original, 'PrivacyInfo.xcprivacy')
        if File.file?(privacy)
          destination = File.join(generated, 'Resources', name)
          FileUtils.mkdir_p(destination)
          FileUtils.cp(privacy, destination)
        end
        puts "  device: arm64; simulator: arm64 + x86_64 (#{count} platform commands patched)"
      end

      FileUtils.cp(manifest_path, File.join(generated, 'Notices', 'mlkit-binaries.json'))
      %w[Frameworks Resources Notices].each do |dir|
        destination = File.join(ROOT, 'ios', dir)
        FileUtils.rm_rf(destination)
        FileUtils.mv(File.join(generated, dir), destination)
      end
    end
    puts 'Prepared iOS XCFrameworks, resources, privacy manifests, and Google notices.'
  end
end

DigitalInkFrameworks.prepare if $PROGRAM_NAME == __FILE__
