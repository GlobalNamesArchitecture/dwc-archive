require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dwc-archive"
    gem.summary = %Q{Handler of Darwin Core Archive files}
    gem.description = %q{Darwin Core Archive is the current standard exchange format for GLobal Names Architecture modules. This gem makes it easy to incorporate files in Darwin Core Archive format into a ruby project.}
    gem.email = "dmozzherin at gmail dot com"
    gem.homepage = "http://github.com/GlobalNamesArchitecture/dwc-archive"
    gem.authors = ["Dmitry Mozzherin"]
    #gem.add_dependency "fastercsv" if RUBY_VERSION.match /^1.8/
    gem.add_dependency 'parsley-store', ">= 0.2.0"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "cucumber", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "dwc-archive #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
