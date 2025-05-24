# frozen_string_literal: true

require "english"

require_relative "bumpit/managers"
require_relative "bumpit/version"

class Bumpit
  WORD_WRAP_MATCHER = /(.{1,78})(?:[^\S\n]+\n?|\n*\Z|\n)|\n/
  WORD_WRAP_PREFIX  = "* "

  # Initialize an instance.
  #
  # @param commit   [Boolean] Whether or not to commit the changes.
  # @param pristine [Boolean] Whether or not to require a pristine directory.
  # @param verify   [String]  Optional command to verify the changes.
  # @return [void]
  def initialize(commit: false, pristine: false, verify: nil)
    @commit   = commit
    @pristine = pristine
    @verify   = verify
  end

  # Bump it!
  #
  # @return [void]
  def call
    ensure_pristine!
    bump!
    verify!
    commit!
  end

  private

  attr_reader :commit, :pristine, :verify

  # Find valid dependency managers and bump their dependencies.
  #
  # @return [void]
  def bump!
    managers.each(&:bump)
  end

  # Print a commit message, if requested and messages are present.
  #
  # @return [void]
  def commit!
    if commit
      messages = managers.filter_map(&:message).flatten

      if messages.any?
        puts "Update dependencies.\n\n"
        puts(messages.map { |message| word_wrap(message) })
      end
    end
  end

  # Ensure the working directory is pristine, if requested.
  #
  # @return [void]
  def ensure_pristine!
    if pristine && `git status --porcelain`.strip != ""
      warn "Working directory must be pristine to run."
      exit 1
    end
  end

  # Return instances of valid managers.
  #
  # @return [Array]
  def managers
    @managers ||= [
      Managers::Bundler,
      Managers::Yarn
    ].select(&:valid?).map(&:new)
  end

  # Verify the changes via a system command, if requested.
  #
  # @return [void]
  def verify!
    if verify
      system(verify)

      unless $CHILD_STATUS.success?
        warn "The `#{verify}` verification command failed."

        exit $CHILD_STATUS.exitstatus
      end
    end
  end

  # Wrap text to fit within 80 characters.
  #
  # @param [String] text The text to wrap.
  # @return [String] The wrapped text.
  def word_wrap(text)
    WORD_WRAP_PREFIX + text.gsub(WORD_WRAP_MATCHER, "\\1\n#{" " * WORD_WRAP_PREFIX.size}").strip
  end
end
