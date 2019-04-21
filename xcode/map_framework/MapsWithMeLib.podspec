
Pod::Spec.new do |spec|

spec.name         = "MapsWithMeLib"
spec.version      = "1.0.3"
spec.license      = "MIT"
spec.homepage     = "https://wifimap.io"
spec.summary      = "maps.me framework"
spec.author       = { 
	"Dmitry Letko" => "d.letko@wifimap.io",
	"Oleg Sorochich" => "oleg@wifimap.io" 
}

spec.platform = :ios
spec.requires_arc = true
spec.static_framework = false

spec.ios.deployment_target = '10.0'
spec.ios.frameworks = 'UIKit', 'QuartzCore', 'Metal', 'MetalKit', 'MetalPerformanceShaders', 'CoreLocation'
spec.ios.vendored_frameworks = 'MapsWithMeLib.framework'

spec.source = { :http => 'https://www.dropbox.com/s/2rxu0ek9lrjph4k/MapsWithMeLib.framework.1.0.3.zip' }

end
