# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts a PowerPoint .pptx deck into Markdown: a `## Slide N` heading per
    # slide followed by its text (one line per paragraph).
    class Pptx < Base
      SLIDE_PATTERN = %r{\Appt/slides/slide(\d+)\.xml\z}.freeze

      def accepts?(_io, stream_info)
        matches?(
          stream_info,
          extensions: %w[pptx],
          mimetypes: %w[application/vnd.openxmlformats-officedocument.presentationml.presentation]
        )
      end

      def convert(io, _stream_info, **_options)
        Markdownator.require_optional("zip", feature: "PPTX conversion")
        Markdownator.require_optional("nokogiri", feature: "PPTX conversion")

        sections = []
        ::Zip::File.open_buffer(io) do |zip|
          slides = zip.entries.select { |e| e.name.match?(SLIDE_PATTERN) }
          slides.sort_by! { |e| e.name[SLIDE_PATTERN, 1].to_i }
          slides.each_with_index do |entry, index|
            sections << render_slide(entry.get_input_stream.read, index + 1)
          end
        end
        Result.new(markdown: sections.join("\n\n"))
      end

      private

      def render_slide(xml, number)
        doc = Nokogiri::XML(xml)
        doc.remove_namespaces!
        lines = doc.xpath("//p").map do |para|
          para.xpath(".//t").map(&:text).join.strip
        end
        lines.reject!(&:empty?)
        body = lines.empty? ? "" : "\n\n#{lines.join("\n")}"
        "## Slide #{number}#{body}"
      end
    end
  end
end
