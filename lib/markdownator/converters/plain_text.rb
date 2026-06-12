# frozen_string_literal: true

module Markdownator
  module Converters
    # Passes plain text (and Markdown) through unchanged.
    class PlainText < Base
      EXTENSIONS = %w[txt text md markdown].freeze
      MIMETYPES = %w[text/plain text/markdown].freeze

      def accepts?(_io, stream_info)
        return true if matches?(stream_info, extensions: EXTENSIONS, mimetypes: MIMETYPES)

        mime = stream_info.guessed_mimetype
        !mime.nil? && mime.start_with?("text/")
      end

      def convert(io, stream_info, **_options)
        Result.new(markdown: read_all(io, stream_info).strip)
      end
    end
  end
end
