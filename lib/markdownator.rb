# frozen_string_literal: true

require_relative "markdownator/version"
require_relative "markdownator/errors"
require_relative "markdownator/stream_info"
require_relative "markdownator/result"
require_relative "markdownator/converters/base"
require_relative "markdownator/converters/plain_text"
require_relative "markdownator/converters/html"
require_relative "markdownator/converters/csv"
require_relative "markdownator/converters/json"
require_relative "markdownator/converters/xml"
require_relative "markdownator/converters/docx"
require_relative "markdownator/converters/xlsx"
require_relative "markdownator/converters/pptx"
require_relative "markdownator/converters/pdf"
require_relative "markdownator/converters/epub"
require_relative "markdownator/converters/zip"
require_relative "markdownator/converters/image"
require_relative "markdownator/engine"

# Convert assorted file formats (Office docs, PDF, HTML, structured data,
# archives, images) into LLM-friendly Markdown.
module Markdownator
  class << self
    # Convert a local path, http(s) URL, or open IO stream to Markdown.
    # @return [Markdownator::Result]
    def convert(source, **options)
      default_engine.convert(source, **options)
    end

    # Convert a local file path to Markdown.
    def convert_local(path, **options)
      default_engine.convert_local(path, **options)
    end

    # Convert an open IO stream to Markdown. `stream_info` supplies format hints.
    def convert_stream(io, stream_info = nil, **options)
      default_engine.convert_stream(io, stream_info, **options)
    end

    # Lazily require an optional gem, raising a helpful error if it is missing.
    def require_optional(gem_name, feature:)
      require gem_name
    rescue LoadError
      raise MissingDependencyError,
            "#{feature} requires the '#{gem_name}' gem. Add it to your Gemfile: gem \"#{gem_name}\""
    end

    private

    def default_engine
      @default_engine ||= Engine.new
    end
  end
end
