#
## NewlandBLEScanner PodSpec
#



Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name                = 'NewlandBLEScanner'
  s.version             = '1.0.0'
  s.summary             = 'CarEasyApps Component : NewlandBLEScanner'
  s.description         = <<-DESC
                            * CarEasyApps Component : 'NewlandBLEScanner'
                          DESC

  s.homepage            = 'https://github.psa-cloud.com/cd200/NewlandBLEScanner-ios'

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license             = { :type => 'Copyright', 
                            :text => <<-LICENSE
                                      * Copyright 2023
                                      * Permission is granted to Stellantis
                                      * All Rights Reserved
                                     LICENSE
                          }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author                = { "IMSC" => "Infrastructure Mutualized Service Center" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform              = :ios
  s.ios.deployment_target = '10.0'
  s.swift_version = "5.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => 'https://github.com/algonrey/NewlandBLEScanner' }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files          = 'NewlandBLEScanner/**/*.{h,m,swift}'
  s.public_header_files   = 'NewlandBLEScanner/**/*.h'

  s.resources = ['README.md',"LICENSE"]


  

end
