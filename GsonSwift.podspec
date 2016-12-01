Pod::Spec.new do |s|
  s.name         = 'GsonSwift'
  s.version      = '0.1.1'
  s.authors      = { 'Pei-shiou Huang' => 'ps_huang@jourmap.com' }
  s.homepage     = 'https://github.com/joeyps/GsonSwift'
  s.platform     = :ios
  s.summary      = 'Gson for Swift'
  s.source       = { :git => 'https://github.com/joeyps/GsonSwift.git', :tag => s.version.to_s }
  s.license      = 'MIT'
  s.frameworks   = 'UIKit', 'CoreText', 'CoreGraphics', 'QuartzCore'
  s.source_files = 'GsonSwift'
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.social_media_url = 'https://github.com/joeyps'
end