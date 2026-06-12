# frozen_string_literal: true

module Markdownator
  module Converters
    # Extracts text from a PDF (one block per page) using the `pdf-reader` gem.
    class Pdf < Base
      def accepts?(io, stream_info)
        return true if matches?(stream_info, extensions: %w[pdf], mimetypes: %w[application/pdf])

        magic_pdf?(io)
      end

      def convert(io, _stream_info, **_options)
        Markdownator.require_optional("pdf-reader", feature: "PDF conversion")

        reader = PDF::Reader.new(io)
        pages = reader.pages.map { |page| page.text.strip }
        pages.reject!(&:empty?)
        Result.new(
          markdown: pages.join("\n\n---\n\n"),
          metadata: { page_count: reader.page_count }
        )
      rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
        raise FileConversionError, "Could not read PDF: #{e.message}"
      end

      private

      def magic_pdf?(io)
        io.rewind if io.respond_to?(:rewind)
        io.read(5) == "%PDF-"
      ensure
        io.rewind if io.respond_to?(:rewind)
      end
    end
  end
end
