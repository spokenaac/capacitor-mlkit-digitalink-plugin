# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'prepare-ios-frameworks'

class DigitalInkFrameworksTest < Minitest::Test
  def object(platform = 2)
    # A minimal 64-bit arm64 MH_OBJECT with one LC_BUILD_VERSION and opaque
    # section bytes, so accidental changes outside platform metadata are caught.
    [0xfeedfacf, 0x100000c, 0, 1, 1, 24, 0, 0,
     0x32, 24, platform, 0x0f0500, 0x120000, 0].pack('V*') + 'section-bytes'.b
  end

  def member(name, contents)
    # BSD archive extended names, including repeated names just like MLKitCommon.
    payload = name.b + contents
    header = ["#1/#{name.bytesize}", '0', '0', '0', '100644', payload.bytesize.to_s].zip([16, 12, 6, 6, 8, 10]).map do |value, width|
      value.ljust(width)
    end.join + "`\n"
    header.b + payload + (payload.bytesize.odd? ? "\n".b : ''.b)
  end

  def patch(contents)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'library')
      File.binwrite(path, contents)
      count = DigitalInkFrameworks.patch_simulator!(path)
      return count, File.binread(path)
    end
  end

  def test_only_platform_metadata_changes_in_object
    count, result = patch(object)
    assert_equal 1, count
    assert_equal object(7), result
  end

  def test_archive_preserves_symbol_index_layout_and_duplicate_member_names
    before = DigitalInkFrameworks::AR_MAGIC + member('__.SYMDEF', 'opaque-index') +
             member('globals.o', object) + member('globals.o', object)
    expected = DigitalInkFrameworks::AR_MAGIC + member('__.SYMDEF', 'opaque-index') +
               member('globals.o', object(7)) + member('globals.o', object(7))
    count, result = patch(before)
    assert_equal 2, count
    assert_equal before.bytesize, result.bytesize
    assert_equal expected, result
  end

  def test_rejects_an_unexpected_upstream_platform_without_writing
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'library')
      original = DigitalInkFrameworks::AR_MAGIC + member('first.o', object) + member('second.o', object(1))
      File.binwrite(path, original)
      assert_raises(RuntimeError) { DigitalInkFrameworks.patch_simulator!(path) }
      assert_equal original, File.binread(path)
    end
  end

  def test_rejects_a_truncated_archive
    assert_raises(RuntimeError) { patch(DigitalInkFrameworks::AR_MAGIC + member('globals.o', object)[0...-6]) }
  end

  def test_rejects_missing_platform_commands
    assert_raises(RuntimeError) { patch('unexpected-upstream-binary'.b) }
  end
end
