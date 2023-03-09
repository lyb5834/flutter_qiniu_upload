#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_qiniu_upload.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_qiniu_upload'
  s.version          = '0.0.1'
  s.summary          = 'flutter qiniu sdk，支持v1 v2 上传'
  s.description      = <<-DESC
flutter qiniu sdk，支持v1 v2 上传
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Qiniu'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
