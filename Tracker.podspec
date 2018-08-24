Pod::Spec.new do |s|
  s.name         = 'Tracker'
  s.version      = '0.0.1'
  s.summary      = 'Utility class for hotupdate and map on ios'
  s.description  = 'Tracker is a simple utility class for hotupdate and map on iOS .'
  s.homepage     = 'https://github.com/shangqiu1988/TrackerRNHotUpdate'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'shangqiu1988' => '1017762553@qq.com' }
  s.source       = { :git => 'https://github.com/shangqiu1988/TrackerRNHotUpdate', :branch => "master" }
  s.ios.deployment_target = '9.0'
   
  s.source_files = 'hotUpdate/**/*', 'Controller*.{h,m}','util/*.{h,m}','location/*.{h,m}','map/*.{h,m}'
  s.frameworks="CoreLocation","Foundation"
  s.dependency 'React'
  s.dependency "SSZipArchive"
  s.dependency "JSONKit"
  s.dependency 'AMapSearch-NO-IDFA', '~> 6.1.1'
  s.dependency 'AMapLocation-NO-IDFA', '~> 2.6.1'
  s.dependency 'AMapNavi-NO-IDFA', '~> 6.2.0'

end