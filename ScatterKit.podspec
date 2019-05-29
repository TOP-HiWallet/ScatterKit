Pod::Spec.new do |s|
  s.name         = "ScatterKit"
  s.version      = "0.0.7"
  s.swift_version = '4.2'
  s.summary      = "Communicate with Scatter via JavaScript interface"
  s.description  = <<-DESC 
ScatterKit allows communication between Swift applications and web pages that use Scatter for chrome extension or desktop application
                   DESC

  s.homepage     = "https://paytomat.com/"

  s.license      = { :type => "MIT", :file => "LICENSE.md" }

  s.author       = { "Alex Melnichuk" => "a.melnichuk@noisyminer.com" }

  s.platform     = :ios
  s.ios.deployment_target = '9.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/paytomat/ScatterKit.git", :branch => "master", :tag => s.version.to_s }

  s.source_files  = "ScatterKit/ScatterKit/Source/**/*.swift"
  s.resource_bundles = {
      'ScatterKit' => [
	'ScatterKit/ScatterKit/Source/js/scatterkit_browser.js',
	'ScatterKit/ScatterKit/Source/js/scatterkit_desktop.js'
      ]
  }
  s.exclude_files = "Examples/*"
  s.frameworks = 'Foundation', 'UIKit', 'WebKit'
end
