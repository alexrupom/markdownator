# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts an Excel .xlsx workbook into Markdown: one `## SheetName` heading
    # and a Markdown table per sheet.
    #
    # Reads the OOXML zip directly with rubyzip and Nokogiri, the same approach
    # used by the DOCX, PPTX, and EPUB converters.
    class Xlsx < Base
      def accepts?(_io, stream_info)
        matches?(
          stream_info,
          extensions: %w[xlsx],
          mimetypes: %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]
        )
      end

      def convert(io, _stream_info, **_options)
        Markdownator.require_optional("zip", feature: "XLSX conversion")
        Markdownator.require_optional("nokogiri", feature: "XLSX conversion")

        ::Zip::File.open_buffer(io) do |zip|
          shared = shared_strings(zip)
          sections = sheets(zip).filter_map do |name, path|
            table = markdown_table(parse_sheet(read(zip, path), shared))
            "## #{name}\n\n#{table}" unless table.empty?
          end
          return Result.new(markdown: sections.join("\n\n"))
        end
      rescue StandardError => e
        raise FileConversionError, "Could not read XLSX: #{e.message}"
      end

      private

      def read(zip, path)
        zip.find_entry(path)&.get_input_stream&.read
      end

      # Ordered [[sheet_name, worksheet_path], ...] resolved via the workbook
      # relationships.
      def sheets(zip)
        workbook = parse(read(zip, "xl/workbook.xml"))
        return [] if workbook.nil?

        rels = relationships(zip)
        workbook.xpath("//sheets/sheet").filter_map do |sheet|
          path = resolve_target(rels[sheet["id"]])
          [sheet["name"].to_s, path] if path
        end
      end

      def relationships(zip)
        doc = parse(read(zip, "xl/_rels/workbook.xml.rels"))
        return {} if doc.nil?

        doc.xpath("//Relationship").to_h { |rel| [rel["Id"], rel["Target"]] }
      end

      def resolve_target(target)
        return nil if target.nil? || target.empty?

        target = target.delete_prefix("/")
        target.start_with?("xl/") ? target : "xl/#{target}"
      end

      # The shared string table: index -> text.
      def shared_strings(zip)
        doc = parse(read(zip, "xl/sharedStrings.xml"))
        return [] if doc.nil?

        doc.xpath("//si").map { |si| si.xpath(".//t").map(&:text).join }
      end

      def parse_sheet(xml, shared)
        doc = parse(xml)
        return [] if doc.nil?

        doc.xpath("//sheetData/row").map do |row|
          values = {}
          width = 0
          row.xpath("./c").each_with_index do |cell, position|
            column = column_index(cell["r"]) || (position + 1)
            width = column if column > width
            values[column] = cell_value(cell, shared)
          end
          (1..width).map { |i| values[i] || "" }
        end
      end

      def cell_value(cell, shared)
        case cell["t"]
        when "s" then shared[cell.at_xpath("./v")&.text.to_i].to_s
        when "inlineStr" then cell.xpath("./is//t").map(&:text).join
        when "b" then cell.at_xpath("./v")&.text == "1" ? "TRUE" : "FALSE"
        else cell.at_xpath("./v")&.text.to_s
        end
      end

      # Converts a cell reference like "B2" into a 1-based column index (2).
      def column_index(ref)
        letters = ref.to_s[/\A[A-Z]+/i]
        return nil if letters.nil?

        letters.upcase.each_char.reduce(0) { |acc, char| (acc * 26) + (char.ord - 64) }
      end

      def parse(xml)
        return nil if xml.nil?

        doc = Nokogiri::XML(xml)
        doc.remove_namespaces!
        doc
      end
    end
  end
end
