# frozen_string_literal: true

require "json"

module Markdownator
  module Converters
    # Renders JSON as a pretty-printed fenced code block (lossless).
    class Json < Base
      def accepts?(_io, stream_info)
        matches?(stream_info, extensions: %w[json], mimetypes: %w[application/json text/json])
      end

      def convert(io, stream_info, **_options)
        raw = read_all(io, stream_info)
        pretty = JSON.pretty_generate(JSON.parse(raw))
        Result.new(markdown: "```json\n#{pretty}\n```")
      rescue JSON::ParserError => e
        raise FileConversionError, "Could not parse JSON: #{e.message}"
      end
    end
  end
end
