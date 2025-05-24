# frozen_string_literal: true

require "json"
require "pathname"

class Bumpit
  module Managers
    class Yarn < Base
      FILENAMES        = %w(package.json yarn.lock).freeze
      OUTDATED_COMMAND = "npm outdated --json"

      # Determine if the manager is valid.
      #
      # @return [Boolean]
      def self.valid?
        executable?("npm") &&
          executable?("yarn") &&
          FILENAMES.all? do |filename|
            File.exist?(Pathname.new(Dir.pwd).join(filename))
          end
      end

      # Bump the dependencies, if there are any.
      #
      # @return [void]
      def bump
        if outdated.any?
          package_update
          yarn_update
        end
      end

      # Return a message for which dependencies were bumped.
      #
      # @return [String]
      def message
        if outdated.any?
          "Updates #{to_sentence(outdated.keys.sort)} in JavaScript."
        end
      end

      private

      # Update the package.json dependencies.
      #
      # @return [void]
      def package_update
        `yarn up --exact "*"`
      end

      # Return the outdated dependencies.
      #
      # @return [Hash]
      def outdated
        @outdated ||= JSON.parse(`#{OUTDATED_COMMAND}`)
                          .each
                          .with_object({}) do |(name, details), result|
                            result[name] = { current: details["current"], latest: details["latest"] }
                          end
      end

      # Update all Yarn dependencies.
      #
      # @return [void]
      def yarn_update
        `rm yarn.lock`
        `yarn`
      end
    end
  end
end
