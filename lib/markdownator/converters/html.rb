# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts HTML into Markdown using reverse_markdown (Nokogiri-backed).
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
        Markdownator.require_optional("reverse_markdown", feature: "HTML conversion")
        ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).strip
      end

      def self.extract_title(html)
        Markdownator.require_optional("nokogiri", feature: "HTML conversion")
        title = Nokogiri::HTML(html).at_css("title")&.text&.strip
        title unless title.nil? || title.empty?
      end
    end
  end
end
