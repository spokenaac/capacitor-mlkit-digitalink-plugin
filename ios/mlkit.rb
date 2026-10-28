# frozen_string_literal: true

# Shared by the published plugin and the native verification project. These
# dependencies and resources mirror Google's 9.0.0 DigitalInkRecognition pods;
# the three binary pods are replaced by our generated XCFrameworks.
module DigitalInkMLKit
  def self.configure(spec, prefix)
    spec.vendored_frameworks = "#{prefix}Frameworks/*.xcframework"
    spec.preserve_paths = "#{prefix}Notices/**/*"
    spec.resource_bundles = {
      'MLKitDigitalInkRecognition_resource' => ["#{prefix}Resources/MLKitDigitalInkRecognition_resource/**"],
      'MLKitCommon_Privacy' => ["#{prefix}Resources/MLKitCommon/PrivacyInfo.xcprivacy"],
      'MLKitDigitalInkRecognition_Privacy' => ["#{prefix}Resources/MLKitDigitalInkRecognition/PrivacyInfo.xcprivacy"]
    }
    spec.frameworks = 'Foundation', 'LocalAuthentication', 'Network'
    spec.libraries = 'c++', 'sqlite3', 'z'
    spec.dependency 'GTMSessionFetcher/Core', '>= 3.3.2', '< 4.0'
    spec.dependency 'GoogleDataTransport', '~> 10.0'
    spec.dependency 'GoogleToolboxForMac/Logger', '>= 4.2.1', '< 5.0'
    spec.dependency 'GoogleToolboxForMac/NSData+zlib', '>= 4.2.1', '< 5.0'
    spec.dependency 'GoogleUtilities/Logger', '~> 8.0'
    spec.dependency 'GoogleUtilities/UserDefaults', '~> 8.0'
    spec.dependency 'SSZipArchive', '>= 2.5.5', '< 3.0'
  end
end
