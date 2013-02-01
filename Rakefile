require "bundler/gem_tasks"
require "rspec/core/rake_task"
FileList['tasks/**/*.rake'].each { |task| import task }

desc "Run tests"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end

task default: :spec
