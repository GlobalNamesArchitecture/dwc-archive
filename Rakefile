require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

Cucumber::Rake::Task.new(:features)

task :rspec => :check_dependencies
task :features => :check_dependencies

# desc 'Run an IRB session with CSL loaded'
# task :irb, [:script] do |t, args|
#   ARGV.clear
# 
#   require 'irb'
#   require_relative 'lib/dwc-archive'
# 
#   IRB.conf[:SCRIPT] = args.script
#   IRB.start
# end
desc "open an irb session preloaded with this library"
task :console do
  sh "irb -I lib -I extra -r dwc-archive.rb"
end

task :default => :rspec
