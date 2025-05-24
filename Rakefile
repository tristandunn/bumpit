# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rspec_opts = "--color --require spec_helper"
end

RuboCop::RakeTask.new("ruby:lint") do |task|
  task.options = %w(--parallel)
end

namespace :ruby do
  desc "Run all the Ruby tests"
  task test: :spec
end

namespace :check do
  desc "Check the code, without coverage"
  task code: %i(ruby:test ruby:lint)

  desc "Check the code, with coverage"
  task :coverage do
    ENV["COVERAGE"] = "true"

    Rake::Task["check:code"].invoke
  end
end

desc "Check the code"
task check: ["check:coverage"]

task default: :spec
