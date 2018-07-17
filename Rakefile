# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "cucumber/rake/task"

RSpec::Core::RakeTask.new(:rspec) do |rspec|
  rspec.pattern = "spec/**/*_spec.rb"
end

Cucumber::Rake::Task.new(:features)

# task rspec: :check_dependencies
task features: :check_dependencies

desc "open an irb session preloaded with this library"
task :console do
  sh "irb -I lib -I extra -r dwc_archive.rb"
end

task default: :rspec
