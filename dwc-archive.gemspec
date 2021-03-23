# frozen_string_literal: true

require File.expand_path("lib/dwc_archive/version", __dir__)

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

  gem.required_ruby_version = ">= 2.6.0"
  gem.files         = `git ls-files`.split("\n").map(&:strip)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # gem.add_runtime_dependency "minitar", "~> 0.6"
  gem.add_runtime_dependency "biodiversity", "~> 5.2.0"
  gem.add_runtime_dependency "nokogiri", "~> 1.11"

  gem.add_development_dependency "bundler", "~> 2.2"
  gem.add_development_dependency "byebug", "~> 11.1"
  gem.add_development_dependency "cucumber", "~> 5"
  gem.add_development_dependency "git", "~> 1.8"
  gem.add_development_dependency "rake", "~> 13"
  gem.add_development_dependency "rspec", "~> 3.10"
  gem.add_development_dependency "rubocop", "~> 1.8"
  gem.add_development_dependency "solargraph", "~> 0.40"
  gem.add_development_dependency "travis", "~> 1.10"
end
