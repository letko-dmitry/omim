
Pod::Spec.new do |spec|

spec.name         = "MapsWithMeLib"
spec.version      = "1.0.2"
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
spec.ios.frameworks = 'QuartzCore', 'Metal', 'MetalKit', 'MetalPerformanceShaders'
spec.ios.vendored_frameworks = 'MapsWithMeLib.framework'

spec.source = { :http => 'https://www.dropbox.com/s/1l8tebcjtntir3b/MapsWithMeLib.framework.zip' }

end
