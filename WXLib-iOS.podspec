

Pod::Spec.new do |s|

  s.name         = "WXLibB"

  s.version      = "1.1.1"

  s.swift_version = "4.0"

  s.summary      = "wx tool"

  s.description  = <<-DESC
wx tool, share or others
                   DESC

  s.homepage     = "http://gitlab.shenmajr.com/shenma-app/WXLibB"

  s.license      = "MIT"

  s.author             = { "wangtieshan" => "15003836653@163.com" }

  s.platform     = :ios, "8.0"

  #s.source       = { :path => "./WXLib", :tag => s.version }
  s.source       = { :git => "https://github.com/wangning0024/WXLibB.git", :tag => s.version }

  s.framework  = "UIKit"

  s.subspec 'WX' do |sp|

    sp.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }

    sp.source_files  = "WXLib/WX/*.{swift,h}"

    sp.vendored_library = 'WXLib/WX/libWeChatSDK.a'

    sp.frameworks = 'CFNetwork', 'SystemConfiguration', 'CoreFoundation', 'CoreTelephony'

    sp.libraries = 'c++', 'z', 'sqlite3'

  end

  s.subspec 'WXShare' do |sp|

    sp.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }

    sp.source_files  = "WXLib/WXShare/*.{swift,h}"

    sp.resources = ['WXLib/WXShare/WXShare.bundle', 'WXLib/WXShare/WXShareItem.xib']

    sp.dependency 'WXLib/WX'

  end

end
