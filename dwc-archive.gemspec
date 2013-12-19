require File.expand_path('../lib/dwc-archive/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "dwc-archive"
  gem.version       = DarwinCore::VERSION
  gem.authors       = ["Dmitry Mozzherin"]
  gem.email         = ["dmozzherin at gmail dot com"]
  gem.description   = %q{Darwin Core Archive is the current standard exchange 
                          format for GLobal Names Architecture modules.  
                          This gem makes it easy to incorporate files in 
                          Darwin Core Archive format into a ruby project.}
  gem.summary       = %q{Handler of Darwin Core Archive files}
  gem.homepage      = "http://github.com/GlobalNamesArchitecture/dwc-archive"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'nokogiri', '~> 1.6'
  gem.add_runtime_dependency 'parsley-store', '~> 0.3'
  gem.add_runtime_dependency 'archive-tar-minitar', '~> 0.5'
  
  gem.add_development_dependency 'rake', '~> 10.1'
  gem.add_development_dependency 'bundler', '~> 1.3'
  gem.add_development_dependency 'rspec', '~> 2.14'
  gem.add_development_dependency 'cucumber', '~> 1.3'
  gem.add_development_dependency 'coveralls', '~> 0.7'
  gem.add_development_dependency 'debugger', '~> 1.6'
end

