#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'stellar_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Stellar SDK for Flutter.'
  s.homepage         = 'https://github.com/Soneso/stellar_flutter_sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Soneso' => 'stellarsdk@soneso.com' }
  s.source           = { :http => 'https://github.com/Soneso/stellar_flutter_sdk' }
  s.source_files     = 'stellar_flutter_sdk/Sources/stellar_flutter_sdk/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'
end
