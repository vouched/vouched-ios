Pod::Spec.new do |s|
  s.name             = 'Vouched'
  s.version          = '0.4.2'
  s.summary          = 'Making Verifications Fast and Simple.'
  s.description      = <<-DESC
                       The Vouched Library allows for fast and simple verifications using an ID and Selfie.
                       DESC
  s.homepage         = 'https://github.com/vouched/vouched-ios'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.authors          = { "Vouched" => "support@vouched.id" }
  s.source           = { :http => "https://github.com/vouched/vouched-ios/releases/download/v#{s.version}/Vouched.zip" }
  s.ios.deployment_target = '11.0'
  s.ios.vendored_frameworks = "Vouched.framework"
  s.dependency 'TensorFlowLiteSwift', '~> 2.2'
  s.static_framework = true
  s.swift_versions = ['4.0']
end