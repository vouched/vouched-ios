Pod::Spec.new do |s|
  s.name             = 'Vouched'
  s.version          = '0.6.1'
  s.summary          = 'Making Verifications Fast and Simple.'
  s.description      = <<-DESC
                       The Vouched Library allows for fast and simple verifications using an ID and Selfie.
                       DESC
  s.homepage         = 'https://github.com/vouched/vouched-ios'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.authors          = { "Vouched" => "support@vouched.id" }
  s.source           = { :http => "https://github.com/vouched/vouched-ios/releases/download/v#{s.version}/Vouched.zip" }
  s.ios.deployment_target = '12.0'
  s.ios.vendored_frameworks = "Vouched.framework"
  s.dependency 'TensorFlowLiteSwift', '~> 2.2'
  s.dependency 'GoogleMLKit/BarcodeScanning'
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.static_framework = true
  s.swift_versions = ['5.4']
end
