Pod::Spec.new do |s|
  s.name             = 'Vouched'
  s.version          = '1.3.0'
  s.summary          = 'Making Verifications Fast and Simple.'
  s.swift_version    = '5.0'
  s.description      = <<-DESC
                       The Vouched Library allows for fast and simple verifications using an ID and Selfie.
                       DESC
  s.homepage         = 'https://github.com/vouched/vouched-ios'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.authors          = { "Vouched" => "support@vouched.id" }
  s.source           = { :http => "https://github.com/vouched/vouched-ios/releases/download/v#{s.version}/VouchedMobileSDK.zip" }

  s.platform = :ios
  s.ios.deployment_target = '12.0'
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.default_subspec = 'Core'
  s.subspec 'Core' do |cr|
      cr.dependency 'TensorFlowLiteSwift', '2.7.0'
      cr.ios.vendored_frameworks = 'VouchedMobileSDK/VouchedCore.framework'
  end

  s.subspec 'Barcode' do |bc|
      bc.dependency 'Vouched/Core'
      bc.ios.vendored_frameworks = 'VouchedMobileSDK/VouchedCore.framework', 'VouchedMobileSDK/VouchedBarcode.framework'
  end
end
