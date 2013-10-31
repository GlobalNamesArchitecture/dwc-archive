# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dwc-archive/version'
require File.expand_path('../lib/dwc-archive', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "dwc-archive"
  spec.version       = DarwinCore::VERSION
  spec.authors       = ["Dmitry Mozzherin"]
  spec.email         = ["dmozzherin at gmail dot com"]
  spec.description   = %q{Darwin Core Archive is the current standard exchange 
                          format for GLobal Names Architecture modules.  
                          This gem makes it easy to incorporate files in 
                          Darwin Core Archive format into a ruby project.}
  spec.summary       = %q{Handler of Darwin Core Archive files}
  spec.homepage      = "http://github.com/GlobalNamesArchitecture/dwc-archive"
 # spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end

