require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorDigitalink'
  s.static_framework = true
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '12.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
  s.dependency 'GoogleMLKit/DigitalInkRecognition', '2.3.0'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
