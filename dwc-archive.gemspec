require File.expand_path("../lib/dwc_archive/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "dwc-archive"
  gem.version       = DarwinCore::VERSION
  gem.authors       = ["Dmitry Mozzherin"]
  gem.email         = ["dmozzherin at gmail dot com"]
  gem.description   = "Darwin Core Archive is the current standard exchange " \
                      "format for GLobal Names Architecture modules. " \
                      "This gem makes it easy to incorporate files in " \
                      "Darwin Core Archive format into a ruby project."
  gem.summary       = "Handler of Darwin Core Archive files"
  gem.homepage      = "http://github.com/GlobalNamesArchitecture/dwc-archive"
  gem.license       = "MIT"

  gem.required_ruby_version = ">= 1.9.1"
  gem.files         = `git ls-files`.split($RS)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "nokogiri", "~> 1.6"
  gem.add_runtime_dependency "parsley-store", "~> 0.3"
  gem.add_runtime_dependency "archive-tar-minitar", "~> 0.5"

  gem.add_development_dependency "rake", "~> 10.4"
  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "rspec", "~> 3.2"
  gem.add_development_dependency "cucumber", "~> 2.0"
  gem.add_development_dependency "coveralls", "~> 0.8"
  # gem.add_development_dependency "byebug", "~> 3.4"
  gem.add_development_dependency "git", "~> 1.2"
  gem.add_development_dependency "rubocop", "~> 0.30"
  gem.add_development_dependency "travis-lint", "~> 2.0"
end
