require "bundler/gem_tasks"

# Bundler::GemHelper.install_tasks
# require 'bundler/gem_tasks'
# require 'rake/testtasks'
# require 'rubygems'
# require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

# task :spec => :check_dependencies

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort 'Cucumber is not available. In order to run features, ' +
      'you must: sudo gem install cucumber'
  end
end

desc 'Run an IRB session with CSL loaded'
task :irb, [:script] do |t, args|
  ARGV.clear

  require 'irb'
  require_relative 'lib/dwc-archive'

  IRB.conf[:SCRIPT] = args.script
  IRB.start
end

task :default => :spec
