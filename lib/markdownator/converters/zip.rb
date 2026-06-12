# frozen_string_literal: true

require "stringio"

module Markdownator
  module Converters
    # Converts a ZIP archive by recursing each contained file back through the
    # engine and concatenating the results under per-file headings.
    class Zip < Base
      def accepts?(io, stream_info)
        return true if matches?(stream_info, extensions: %w[zip], mimetypes: %w[application/zip])

        magic_zip?(io)
      end

      def convert(io, _stream_info, **options)
        Markdownator.require_optional("zip", feature: "ZIP conversion")
        engine = options[:engine] || Engine.new

        sections = []
        ::Zip::File.open_buffer(io) do |zip|
          zip.entries.sort_by(&:name).each do |entry|
            next if entry.directory?

            section = convert_entry(engine, entry, options)
            sections << section unless section.nil?
          end
        end
        Result.new(markdown: sections.join("\n\n"))
      end

      private

      def convert_entry(engine, entry, options)
        stream_info = StreamInfo.new(
          extension: File.extname(entry.name),
          filename: File.basename(entry.name)
        )
        result = engine.convert_stream(
          StringIO.new(entry.get_input_stream.read),
          stream_info,
          **options.reject { |k, _| k == :engine }
        )
        body = result.markdown.strip
        body.empty? ? nil : "## #{entry.name}\n\n#{body}"
      rescue UnsupportedFormatError, FileConversionError
        nil
      end

      def magic_zip?(io)
        io.rewind if io.respond_to?(:rewind)
        io.read(4) == "PK\x03\x04"
      ensure
        io.rewind if io.respond_to?(:rewind)
      end
    end
  end
end
