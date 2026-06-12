# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts an EPUB into Markdown by reading the OPF spine order and running
    # each XHTML chapter through the HTML converter.
    class Epub < Base
      CONTAINER_PATH = "META-INF/container.xml"

      def accepts?(_io, stream_info)
        matches?(stream_info, extensions: %w[epub], mimetypes: %w[application/epub+zip])
      end

      def convert(io, _stream_info, **_options)
        Markdownator.require_optional("zip", feature: "EPUB conversion")
        Markdownator.require_optional("nokogiri", feature: "EPUB conversion")

        ::Zip::File.open_buffer(io) do |zip|
          opf_path = locate_opf(zip)
          raise FileConversionError, "EPUB is missing its OPF package document" if opf_path.nil?

          opf = Nokogiri::XML(read(zip, opf_path))
          opf.remove_namespaces!
          base = File.dirname(opf_path)
          title = opf.at_xpath("//metadata/title")&.text&.strip
          chapters = spine_documents(zip, opf, base)
          return Result.new(markdown: chapters.join("\n\n"), title: title)
        end
      end

      private

      def locate_opf(zip)
        container = zip.find_entry(CONTAINER_PATH)
        return nil if container.nil?

        doc = Nokogiri::XML(container.get_input_stream.read)
        doc.remove_namespaces!
        doc.at_xpath("//rootfile/@full-path")&.value
      end

      def spine_documents(zip, opf, base)
        manifest = opf.xpath("//manifest/item").to_h do |item|
          [item["id"], item["href"]]
        end

        opf.xpath("//spine/itemref").filter_map do |ref|
          href = manifest[ref["idref"]]
          next if href.nil?

          path = base == "." ? href : File.join(base, href)
          html = read(zip, path)
          next if html.nil?

          Html.html_to_markdown(html)
        end
      end

      def read(zip, path)
        zip.find_entry(path)&.get_input_stream&.read
      end
    end
  end
end
