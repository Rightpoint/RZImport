Pod::Spec.new do |s|
  s.name                  = "RZImport"
  s.version               = "1.2.1"
  s.summary               = "Automatic model object deserialization from NSDictionary"

  s.description           = <<-DESC
                          Tired of writing boilerplate to import deserialized API responses to model objects?

                          Tired of dealing with dozens and dozens of string keys?

                          RZImport is here to help!

                          RZImport is a category on NSObject and an accompanying optional protocol for creating and updating model objects 
                          in your iOS applications. It's particularly useful for importing objects from deserialized JSON HTTP responses 
                          in REST APIs, but it works with any NSDictionary or array of dictionaries that you need to convert to native 
                          model objects.
                          DESC
                          
  s.homepage              = "https://github.com/raizlabs/RZImport"
  s.license               = { :type => "MIT", :file => "LICENSE" }
  s.author                = { "Nick Donaldson" => "nick.donaldson@raizlabs.com" }
  s.social_media_url      = "http://twitter.com/raizlabs"
  
  s.ios.deployment_target = "6.1"
  s.osx.deployment_target = "10.8"
  
  s.source                = { :git => "https://github.com/Raizlabs/RZImport.git", :tag => "1.2.1" }
  s.source_files          = "Classes/*.{h,m}", "Classes/Private/*.{h,m}"
  s.private_header_files  = "Classes/Private/*.h"
  s.framework             = "Foundation"
  s.requires_arc          = true
end
