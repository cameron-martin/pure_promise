require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :mutant do
  system 'mutant --include lib --require pure_promise --use rspec PurePromise*'
end