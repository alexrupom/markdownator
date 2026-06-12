# frozen_string_literal: true

module Markdownator
  module Converters
    # Walks a Nokogiri HTML node tree and renders Markdown. A focused,
    # dependency-free replacement for reverse_markdown: HTML conversion needs
    # only Nokogiri (which reverse_markdown depended on anyway).
    class HtmlRenderer
      # Elements that introduce their own block (line-separated) content.
      BLOCK_TAGS = %w[
        address article aside blockquote details div dl figcaption figure
        footer form h1 h2 h3 h4 h5 h6 header hr main nav ol p pre section
        table ul
      ].freeze

      # Elements whose contents are dropped entirely.
      SKIP_TAGS = %w[script style head title noscript template].freeze

      def render(node)
        blocks_to_string(render_blocks(node))
      end

      private

      # Renders the children of +node+ into an array of block strings, grouping
      # consecutive inline content into paragraphs.
      def render_blocks(node)
        blocks = []
        buffer = +""

        node.children.each do |child|
          if block?(child)
            push_paragraph(blocks, buffer)
            buffer = +""
            block = render_block(child)
            blocks << block unless block.nil? || block.empty?
          elsif !skip?(child)
            buffer << render_inline(child)
          end
        end
        push_paragraph(blocks, buffer)
        blocks
      end

      def render_block(node)
        case node.name
        when /\Ah([1-6])\z/ then "#{"#" * Regexp.last_match(1).to_i} #{inline_of(node)}"
        when "ul" then render_list(node, ordered: false)
        when "ol" then render_list(node, ordered: true)
        when "pre" then render_pre(node)
        when "blockquote" then render_blockquote(node)
        when "table" then render_table(node)
        when "dl" then render_definition_list(node)
        when "hr" then "---"
        else blocks_to_string(render_blocks(node)) # div, section, p, unknown blocks
        end
      end

      def render_inline(node)
        return normalize(node.text) if node.text?
        return "" if node.comment? || skip?(node)

        case node.name
        when "strong", "b" then emphasis(node, "**")
        when "em", "i" then emphasis(node, "_")
        when "del", "s", "strike" then emphasis(node, "~~")
        when "code" then inline_code(node)
        when "a" then render_link(node)
        when "img" then render_image(node)
        when "br" then "\n"
        else inline_of(node)
        end
      end

      def render_link(node)
        href = node["href"].to_s.strip
        text = inline_of(node)
        text = href if text.empty?
        href.empty? ? text : "[#{text}](#{href})"
      end

      def render_image(node)
        "![#{node["alt"].to_s.strip}](#{node["src"].to_s.strip})"
      end

      def render_list(node, ordered:)
        index = 0
        list_items(node).map do |li|
          index += 1
          marker = ordered ? "#{index}." : "-"
          indent = " " * (marker.length + 1)
          lines = blocks_to_string(render_blocks(li)).split("\n")
          first = lines.shift.to_s
          rest = lines.map { |line| line.empty? ? "" : "#{indent}#{line}" }
          (["#{marker} #{first}"] + rest).join("\n")
        end.join("\n")
      end

      def render_pre(node)
        code = node.at_css("code") || node
        language = code["class"].to_s[/(?:language|lang)-(\w+)/, 1].to_s
        "```#{language}\n#{code.text.chomp}\n```"
      end

      def render_blockquote(node)
        blocks_to_string(render_blocks(node)).split("\n").map do |line|
          line.empty? ? ">" : "> #{line}"
        end.join("\n")
      end

      def render_table(node)
        rows = node.css("tr").map do |tr|
          tr.css("th, td").map { |cell| inline_of(cell).gsub("|", "\\|") }
        end
        rows.reject!(&:empty?)
        return "" if rows.empty?

        width = rows.map(&:length).max
        rows.each { |row| row.fill("", row.length...width) }
        header, *body = rows
        lines = ["| #{header.join(" | ")} |", "| #{Array.new(width, "---").join(" | ")} |"]
        body.each { |row| lines << "| #{row.join(" | ")} |" }
        lines.join("\n")
      end

      def render_definition_list(node)
        node.element_children.map do |child|
          text = inline_of(child)
          next if text.empty?

          child.name == "dt" ? "**#{text}**" : ": #{text}"
        end.compact.join("\n")
      end

      # --- helpers ---------------------------------------------------------

      def inline_code(node)
        text = node.text
        fence = text.include?("`") ? "`` " : "`"
        close = text.include?("`") ? " ``" : "`"
        "#{fence}#{text}#{close}"
      end

      def emphasis(node, marker)
        inner = inline_of(node)
        inner.empty? ? "" : "#{marker}#{inner}#{marker}"
      end

      # Inline content of a node, with surrounding whitespace collapsed.
      def inline_of(node)
        clean_inline(node.children.map { |child| render_inline(child) }.join)
      end

      def list_items(node)
        node.element_children.select { |child| child.name == "li" }
      end

      def push_paragraph(blocks, buffer)
        text = clean_block(buffer)
        blocks << text unless text.empty?
      end

      def blocks_to_string(blocks)
        blocks.reject(&:empty?).join("\n\n")
      end

      # Collapses source whitespace (including newlines) to single spaces, so
      # only explicit <br> newlines survive.
      def normalize(text)
        text.gsub(/\s+/, " ")
      end

      def clean_inline(text)
        text.gsub(/[ \t]{2,}/, " ").strip
      end

      def clean_block(text)
        text.gsub(/ *\n */, "\n").gsub(/[ \t]{2,}/, " ").gsub(/\n{3,}/, "\n\n").strip
      end

      def block?(node)
        node.element? && BLOCK_TAGS.include?(node.name)
      end

      def skip?(node)
        node.element? && SKIP_TAGS.include?(node.name)
      end
    end
  end
end
