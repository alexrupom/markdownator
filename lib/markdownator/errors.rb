# frozen_string_literal: true

module Markdownator
  # Base error for all Markdownator failures.
  class Error < StandardError; end

  # Raised when no registered converter accepts the given input.
  class UnsupportedFormatError < Error; end

  # Raised when a converter needs an optional gem that is not installed.
  class MissingDependencyError < Error; end

  # Raised when a converter accepts the input but fails to convert it.
  class FileConversionError < Error; end
end
