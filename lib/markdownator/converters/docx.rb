# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts a Word .docx (Office Open XML) document into Markdown.
    #
    # A .docx is a ZIP whose `word/document.xml` holds the body. We map heading
    # styles to `#` levels, list paragraphs to bullets, and `w:tbl` to Markdown
    # tables.
    class Docx < Base
      W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

      def accepts?(_io, stream_info)
        matches?(
          stream_info,
          extensions: %w[docx],
          mimetypes: %w[application/vnd.openxmlformats-officedocument.wordprocessingml.document]
        )
      end

      def convert(io, _stream_info, **_options)
        Markdownator.require_optional("zip", feature: "DOCX conversion")
        Markdownator.require_optional("nokogiri", feature: "DOCX conversion")

        xml = read_entry(io, "word/document.xml")
        raise FileConversionError, "DOCX is missing word/document.xml" if xml.nil?

        doc = Nokogiri::XML(xml)
        doc.remove_namespaces!
        body = doc.at_xpath("//body")
        blocks = body.nil? ? [] : body.element_children.filter_map { |node| render_block(node) }
        Result.new(markdown: blocks.join("\n\n"))
      end

      private

      def read_entry(io, name)
        ::Zip::File.open_buffer(io) do |zip|
          entry = zip.find_entry(name)
          return entry&.get_input_stream&.read
        end
      end

      def render_block(node)
        case node.name
        when "p" then render_paragraph(node)
        when "tbl" then render_table(node)
        end
      end

      def render_paragraph(para)
        text = para.xpath(".//t").map(&:text).join.strip
        return nil if text.empty?

        style = para.at_xpath(".//pStyle/@val")&.value.to_s
        if (level = heading_level(style))
          "#{"#" * level} #{text}"
        elsif style.match?(/ListParagraph/i) || !para.at_xpath(".//numPr").nil?
          "- #{text}"
        else
          text
        end
      end

      def heading_level(style)
        match = style.match(/\AHeading(\d)/i) || style.match(/\ATitle\z/i)
        return nil if match.nil?

        match[1] ? match[1].to_i.clamp(1, 6) : 1
      end

      def render_table(table)
        rows = table.xpath("./tr").map do |tr|
          tr.xpath("./tc").map { |tc| tc.xpath(".//t").map(&:text).join.strip }
        end
        rows.empty? ? nil : markdown_table(rows)
      end
    end
  end
end
