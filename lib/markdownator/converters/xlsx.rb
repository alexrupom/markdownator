# frozen_string_literal: true

require "tempfile"

module Markdownator
  module Converters
    # Converts an Excel .xlsx workbook into Markdown: one `## SheetName` heading
    # and a Markdown table per sheet, using the `roo` gem.
    class Xlsx < Base
      def accepts?(_io, stream_info)
        matches?(
          stream_info,
          extensions: %w[xlsx],
          mimetypes: %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]
        )
      end

      def convert(io, _stream_info, **_options)
        Markdownator.require_optional("roo", feature: "XLSX conversion")

        with_tempfile(io) do |path|
          workbook = Roo::Excelx.new(path)
          sections = workbook.sheets.map { |name| render_sheet(workbook, name) }
          Result.new(markdown: sections.compact.join("\n\n"))
        end
      rescue StandardError => e
        raise FileConversionError, "Could not read XLSX: #{e.message}"
      end

      private

      def render_sheet(workbook, name)
        sheet = workbook.sheet(name)
        rows = (1..sheet.last_row.to_i).map do |r|
          (1..sheet.last_column.to_i).map { |c| sheet.cell(r, c) }
        end
        table = markdown_table(rows)
        table.empty? ? nil : "## #{name}\n\n#{table}"
      end

      def with_tempfile(io)
        Tempfile.create(["markdownator", ".xlsx"]) do |file|
          file.binmode
          file.write(io.read)
          file.flush
          yield file.path
        end
      end
    end
  end
end
