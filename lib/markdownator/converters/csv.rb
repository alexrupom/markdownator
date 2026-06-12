# frozen_string_literal: true

require "csv"

module Markdownator
  module Converters
    # Converts CSV into a GitHub-flavored Markdown table.
    class Csv < Base
      def accepts?(_io, stream_info)
        matches?(stream_info, extensions: %w[csv], mimetypes: %w[text/csv application/csv])
      end

      def convert(io, stream_info, **_options)
        rows = CSV.parse(read_all(io, stream_info))
        Result.new(markdown: markdown_table(rows))
      rescue CSV::MalformedCSVError => e
        raise FileConversionError, "Could not parse CSV: #{e.message}"
      end
    end
  end
end
