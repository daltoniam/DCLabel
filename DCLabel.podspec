Pod::Spec.new do |s|
  s.name         = "DCLabel"
  s.version      = "0.0.1"
  s.summary      = "Extends UILabel attributedText drawing to make embedding images/video content simple. Also has a powerful parsing engine to convert text tags to attributed strings."
  s.homepage     = "https://github.com/daltoniam/DCLabel"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Dalton Cherry" => "daltoniam@gmail.com" }
  s.source       = { :git => "https://github.com/daltoniam/DCLabel.git" }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.source_files = '*.{h,m}'
  #s.public_header_files = '*.h'
  s.framework  = 'CoreText'
  s.library   = 'CoreText'
  s.requires_arc = true
end
