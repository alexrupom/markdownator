# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts XML into an indented Markdown outline of elements and their text.
    class Xml < Base
      def accepts?(_io, stream_info)
        matches?(stream_info, extensions: %w[xml], mimetypes: %w[application/xml text/xml])
      end

      def convert(io, stream_info, **_options)
        Markdownator.require_optional("nokogiri", feature: "XML conversion")
        doc = Nokogiri::XML(read_all(io, stream_info))
        raise FileConversionError, "Could not parse XML" if doc.root.nil?

        lines = []
        walk(doc.root, 0, lines)
        Result.new(markdown: lines.join("\n"))
      end

      private

      def walk(node, depth, lines)
        indent = "  " * depth
        children = node.element_children
        own_text = node.xpath("./text()").map(&:text).join(" ").gsub(/\s+/, " ").strip

        label = node.name
        label = "#{label}: #{own_text}" unless own_text.empty?
        lines << "#{indent}- #{label}"

        children.each { |child| walk(child, depth + 1, lines) }
      end
    end
  end
end
