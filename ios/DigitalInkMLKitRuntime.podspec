# Development-only binary pod for the standalone Plugin.xcodeproj test harness.
require_relative 'mlkit'

Pod::Spec.new do |s|
  s.name = 'DigitalInkMLKitRuntime'
  s.version = '9.0.0'
  s.summary = 'ML Kit Digital Ink binaries used by the plugin verification project'
  s.homepage = 'https://developers.google.com/ml-kit/vision/digital-ink-recognition'
  s.license = { :type => 'Copyright', :text => 'Copyright 2025 Google LLC. See Notices/.' }
  s.author = 'Google, Inc.'
  s.source = { :git => 'https://github.com/spokenaac/capacitor-mlkit-digitalink-plugin.git' }
  s.ios.deployment_target = '15.5'
  s.static_framework = true
  DigitalInkMLKit.configure(s, '')
end
