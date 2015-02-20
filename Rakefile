require "bundler/gem_tasks"
require "rspec/core/rake_task"
# FileList['tasks/**/*.rake'].each { |task| import task }

desc "Run tests"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end

namespace :spec do
  desc "Run tests, deleting today's auth data file beforehand."
  task clear_auth: [:rmauth, :spec]

  desc "Run tests, deleting vcr_cassettes beforehand."
  task clear_cassettes: [:rmvcr, :spec]

  desc "Run tests, deleting both cassettes and auth data file beforehand."
  task clear_all: [:rmvcr, :rmauth, :spec]
end

desc "Deletes todays auth data file."
task :rmauth do
  puts 'Deleting file...'
  `rm /tmp/bravo*`
  puts 'Done, moving on.'
end

desc "Deletes vcr cassettes."
task :rmvcr do
  puts 'Deleting cassettes...'
  `rm -rf spec/fixtures/vcr_cassettes`
  puts 'Done, moving on.'
end
task default: :spec
