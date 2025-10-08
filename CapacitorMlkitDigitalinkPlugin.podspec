require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorMlkitDigitalinkPlugin'
  s.static_framework = true
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '15.5'
  s.dependency 'Capacitor'
  s.swift_version = '5.9'
  s.dependency 'GoogleMLKit/DigitalInkRecognition', '9.0.0'
end
