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
    it "converts HTML to Markdown and extracts the title" do
      html = "<html><head><title>Doc</title></head><body><h1>Hi</h1><p>Body</p></body></html>"
      result = convert(html, "html")

      expect(result.markdown).to eq("# Hi\n\nBody")
      expect(result.title).to eq("Doc")
    end
  end
end
