# frozen_string_literal: true

require_relative "lib/bumpit/version"

Gem::Specification.new do |s|
  s.name        = "bumpit"
  s.version     = Bumpit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tristan Dunn"]
  s.email       = "hello@tristandunn.com"
  s.homepage    = "https://github.com/tristandunn/bumpit"
  s.summary     = "Automatically bump dependencies in multiple package managers."
  s.description = "Automatically bump dependencies in multiple package managers."
  s.license     = "MIT"
  s.metadata    = {
    "bug_tracker_uri"       => "https://github.com/tristandunn/bumpit/issues",
    "changelog_uri"         => "https://github.com/tristandunn/bumpit/blob/main/CHANGELOG.md",
    "github_repo"           => "https://github.com/tristandunn/bumpit",
    "rubygems_mfa_required" => "true"
  }

  s.files         = Dir["lib/**/*"].to_a
  s.bindir        = "exe"
  s.executables   = ["bumpit"]
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.4"

  s.add_dependency "bundler",  "~> 4.0"
  s.add_dependency "json",     "~> 2.10"
end
