# frozen_string_literal: true

RSpec.describe "Text-based converters" do
  def convert(body, extension, **opts)
    info = Markdownator::StreamInfo.new(extension: extension)
    Markdownator.convert_stream(StringIO.new(body), info, **opts)
  end

  describe Markdownator::Converters::PlainText do
    it "passes text through, stripped" do
      expect(convert("  hello world  ", "txt").markdown).to eq("hello world")
    end
  end

  describe Markdownator::Converters::Csv do
    it "renders a GitHub Markdown table" do
      expect(convert("a,b\n1,2\n3,4", "csv").markdown)
        .to eq("| a | b |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |")
    end

    it "raises FileConversionError on malformed CSV" do
      expect { convert("a,\"unterminated", "csv") }
        .to raise_error(Markdownator::FileConversionError, /Could not parse CSV/)
    end
  end

  describe Markdownator::Converters::Json do
    it "pretty-prints inside a fenced json block" do
      expect(convert('{"a":1}', "json").markdown).to eq("```json\n{\n  \"a\": 1\n}\n```")
    end

    it "raises FileConversionError on invalid JSON" do
      expect { convert("{not json}", "json") }
        .to raise_error(Markdownator::FileConversionError, /Could not parse JSON/)
    end
  end

  describe Markdownator::Converters::Xml do
    it "produces an indented outline of elements and text" do
      xml = "<root><item>x</item><item>y</item></root>"
      expect(convert(xml, "xml").markdown).to eq("- root\n  - item: x\n  - item: y")
    end
  end

  describe Markdownator::Converters::Html do
    it "converts headings and paragraphs and extracts the title" do
      html = "<html><head><title>Doc</title></head><body><h1>Hi</h1><p>Body</p></body></html>"
      result = convert(html, "html")

      expect(result.markdown).to eq("# Hi\n\nBody")
      expect(result.title).to eq("Doc")
    end

    it "renders inline emphasis, links, and images" do
      html = "<p>See <strong>this</strong> and <em>that</em>, " \
             'a <a href="https://x.test">link</a> and <img src="a.png" alt="pic">.</p>'

      expect(convert(html, "html").markdown)
        .to eq("See **this** and _that_, a [link](https://x.test) and ![pic](a.png).")
    end

    it "renders unordered and ordered lists" do
      html = "<ul><li>one</li><li>two</li></ul><ol><li>first</li><li>second</li></ol>"

      expect(convert(html, "html").markdown)
        .to eq("- one\n- two\n\n1. first\n2. second")
    end

    it "renders inline code, code blocks, blockquotes, and tables" do
      html = "<p>Use <code>x</code>.</p>" \
             "<pre><code class=\"language-ruby\">puts 1</code></pre>" \
             "<blockquote><p>quoted</p></blockquote>" \
             "<table><tr><th>A</th><th>B</th></tr><tr><td>1</td><td>2</td></tr></table>"
      markdown = convert(html, "html").markdown

      expect(markdown).to include("Use `x`.")
      expect(markdown).to include("```ruby\nputs 1\n```")
      expect(markdown).to include("> quoted")
      expect(markdown).to include("| A | B |\n| --- | --- |\n| 1 | 2 |")
    end

    it "collapses source whitespace while keeping explicit line breaks" do
      html = "<p>first\n   line<br>second line</p>"

      expect(convert(html, "html").markdown).to eq("first line\nsecond line")
    end
  end
end
