# frozen_string_literal: true

require "bundler/cli/update"
require "pathname"

class Bumpit
  module Managers
    class Bundler < Base
      DEPENDENCY_MATCHER = /^\s*gem\s+['"]([^'"]+)['"].*$/
      FILENAMES          = %w(Gemfile Gemfile.lock).freeze
      OUTDATED_COMMAND   = "bundle outdated --only-explicit --parseable 2>/dev/null"
      OUTDATED_MATCHER   = /\A(.+) \(newest (.+), installed (.+), requested = (.+)\)\z/

      # Determine if the manager is valid.
      #
      # @return [Boolean]
      def self.valid?
        executable?("bundle") &&
          FILENAMES.all? do |filename|
            File.exist?(Pathname.new(Dir.pwd).join(filename))
          end
      end

      # Bump the dependencies, if there are any.
      #
      # @return [void]
      def bump
        if outdated.any?
          write_contents
          bundle_update
        end
      end

      # Return a message for which dependencies were bumped.
      #
      # @return [String]
      def message
        if outdated.any?
          "Updates #{to_sentence(outdated.keys.sort)} in Ruby."
        end
      end

      private

      # Reset the existing cache and settings and run update for Bundler.
      #
      # @return [void]
      def bundle_update
        silence_output do
          ::Bundler.clear_gemspec_cache
          ::Bundler.reset!
          ::Bundler.reset_settings_and_root!

          ::Bundler::CLI::Update.new({ all: true }, []).run
        end
      end

      # Return the contents of the Gemfile.
      #
      # @return [String] The contents of the Gemfile.
      def contents
        @contents ||= File.read("Gemfile")
      end

      # Return the modified contents of the Gemfile.
      #
      # @return [Array]
      def modified_contents
        contents.split("\n").map do |line|
          _, name = line.match(DEPENDENCY_MATCHER).to_a
          dependency = outdated[name]

          if dependency
            line.gsub(dependency[:current], dependency[:latest])
          else
            line
          end
        end
      end

      # Return the outdated dependencies.
      #
      # @return [Hash]
      def outdated
        @outdated ||= `#{OUTDATED_COMMAND}`.split("\n").each.with_object({}) do |dependency, result|
          if dependency.match(OUTDATED_MATCHER)
            _, name, latest, _, current = dependency.match(OUTDATED_MATCHER).to_a

            result[name] = { current: current, latest: latest }
          end
        end
      end

      # Write the file with the bumped dependencies.
      #
      # @return [void]
      def write_contents
        File.write("Gemfile", "#{modified_contents.join("\n")}\n")
      end
    end
  end
end
