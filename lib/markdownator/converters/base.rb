# frozen_string_literal: true

module Markdownator
  module Converters
    # Abstract base class for all converters.
    #
    # A converter is asked, in priority order, whether it `accepts?` a stream;
    # the first one that does has its `convert` called. Subclasses must override
    # both methods. The stream passed in is a rewound IO positioned at byte 0.
    class Base
      # @return [Boolean] whether this converter can handle the given stream.
      def accepts?(_io, _stream_info)
        raise NotImplementedError, "#{self.class} must implement #accepts?"
      end

      # @return [Markdownator::Result]
      def convert(_io, _stream_info, **_options)
        raise NotImplementedError, "#{self.class} must implement #convert"
      end

      private

      # True when the stream's extension or guessed mimetype matches.
      def matches?(stream_info, extensions: [], mimetypes: [])
        ext = stream_info.extension
        return true if ext && extensions.include?(ext)

        mime = stream_info.guessed_mimetype
        return true if mime && mimetypes.include?(mime)

        false
      end

      # Reads the full stream as a String, honoring the charset hint when present.
      def read_all(io, stream_info)
        data = io.read
        return "" if data.nil?

        data = data.dup
        encoding = stream_info.charset
        data.force_encoding(encoding) if encoding && Encoding.name_list.include?(encoding)
        data.valid_encoding? ? data : data.encode("UTF-8", invalid: :replace, undef: :replace)
      end

      # Builds a GitHub-flavored Markdown table from a header row and body rows.
      # Empty input yields an empty string.
      def markdown_table(rows)
        rows = rows.map { |row| Array(row).map { |cell| format_cell(cell) } }
        rows.reject!(&:empty?)
        return "" if rows.empty?

        width = rows.map(&:length).max
        rows.each { |row| row.fill("", row.length...width) }

        header = rows.first
        body = rows[1..] || []
        lines = []
        lines << "| #{header.join(" | ")} |"
        lines << "| #{Array.new(width, "---").join(" | ")} |"
        body.each { |row| lines << "| #{row.join(" | ")} |" }
        lines.join("\n")
      end

      def format_cell(cell)
        cell.to_s.gsub(/\s+/, " ").strip.gsub("|", "\\|")
      end
    end
  end
end
