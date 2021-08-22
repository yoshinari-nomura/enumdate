# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "yard"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

YARD::Rake::YardocTask.new do |t|
  t.options = ["-m", "org"]
end

task doc: %i[yard]
task default: %i[test rubocop]
