# frozen_string_literal: true

require "bundler"

# :nocov:
class Bumpit
  module Managers
    class Base
      # Return if an executable exists or not.
      #
      # @return [Boolean]
      def self.executable?(executable)
        !::Bundler.which(executable).nil?
      end

      protected

      # Silence the output of the provided block.
      #
      # @param block [Block] The block to silence output for.
      # @return [void]
      def silence_output(&)
        original_stdout = $stdout.clone
        original_stderr = $stderr.clone

        $stdout = $stderr = File.new(File::NULL, "w")

        yield
      ensure
        $stdout = original_stdout
        $stderr = original_stderr
      end

      # Convert an array to a sentence.
      #
      # @param [Array] array The array to convert to a sentence.
      # @return [String]
      def to_sentence(array)
        case array.length
        when 0
          +""
        when 1
          array.first
        when 2
          "#{array[0]} and #{array[1]}"
        else
          "#{array[0...-1].join(", ")}, and #{array[-1]}"
        end
      end
    end
  end
end
# :nocov:
