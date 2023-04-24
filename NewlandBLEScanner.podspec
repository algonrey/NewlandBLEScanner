#
## NewlandBLEScanner PodSpec
#



Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name                = 'NewlandBLEScanner'
  s.version             = '1.0.0'
  s.summary             = 'Library to simplify the use of the Newland BLE Scanners'
  s.homepage            = 'https://github.com/algonrey/NewlandBLEScanner'
  s.license             = { :type => 'MIT' }
  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author                = 'alberto.gr' 

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform              = :ios
  s.ios.deployment_target = '10.0'
  s.swift_version = "5.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => 'https://github.com/algonrey/NewlandBLEScanner.git' :tag => '1.0.0' }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files          = 'NewlandBLEScanner/**/*.{h,m,swift}'
  s.public_header_files   = 'NewlandBLEScanner/**/*.h'

  s.resources = ["LICENSE"]


  

end
