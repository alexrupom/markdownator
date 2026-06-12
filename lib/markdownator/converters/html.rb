# frozen_string_literal: true

require_relative "html_renderer"

module Markdownator
  module Converters
    # Converts HTML into Markdown by walking the Nokogiri node tree.
    class Html < Base
      def accepts?(_io, stream_info)
        matches?(stream_info, extensions: %w[html htm], mimetypes: %w[text/html application/xhtml+xml])
      end

      def convert(io, stream_info, **_options)
        html = read_all(io, stream_info)
        Result.new(markdown: self.class.html_to_markdown(html), title: self.class.extract_title(html))
      end

      # Shared so other container converters (EPUB) can reuse HTML conversion.
      def self.html_to_markdown(html)
        Markdownator.require_optional("nokogiri", feature: "HTML conversion")
        doc = Nokogiri::HTML(html)
        root = doc.at_css("body") || doc.root || doc
        HtmlRenderer.new.render(root)
      end

      def self.extract_title(html)
        Markdownator.require_optional("nokogiri", feature: "HTML conversion")
        title = Nokogiri::HTML(html).at_css("title")&.text&.strip
        title unless title.nil? || title.empty?
      end
    end
  end
end
