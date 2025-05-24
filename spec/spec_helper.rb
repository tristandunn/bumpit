# frozen_string_literal: true

if ENV["CI"] || ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-console"

  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
  end
end

require "bumpit"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
