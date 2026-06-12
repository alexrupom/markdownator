# frozen_string_literal: true

RSpec.describe "Office and document converters" do
  def convert(bytes, extension)
    info = Markdownator::StreamInfo.new(extension: extension)
    Markdownator.convert_stream(StringIO.new(bytes), info)
  end

  describe Markdownator::Converters::Docx do
    it "maps headings, paragraphs, and tables to Markdown" do
      markdown = convert(Builders.docx_bytes, "docx").markdown

      expect(markdown).to include("# Greeting")
      expect(markdown).to include("Hello world.")
      expect(markdown).to include("| A | B |\n| --- | --- |\n| 1 | 2 |")
    end
  end

  describe Markdownator::Converters::Xlsx do
    it "renders one heading and table per sheet" do
      markdown = convert(Builders.xlsx_bytes, "xlsx").markdown

      expect(markdown).to include("## Data")
      expect(markdown).to include("| Name | Age |")
      expect(markdown).to include("| Alice | 30 |")
    end
  end

  describe Markdownator::Converters::Pptx do
    it "emits a heading and text per slide, in order" do
      markdown = convert(Builders.pptx_bytes, "pptx").markdown

      expect(markdown).to include("## Slide 1\n\nFirst slide")
      expect(markdown).to include("## Slide 2\n\nSecond slide")
    end
  end

  describe Markdownator::Converters::Pdf do
    it "extracts page text" do
      result = convert(Builders.pdf_bytes, "pdf")

      expect(result.markdown).to include("Hello PDF")
      expect(result.metadata[:page_count]).to eq(1)
    end

    it "accepts a stream by its %PDF magic bytes without an extension" do
      info = Markdownator::StreamInfo.new
      result = Markdownator.convert_stream(StringIO.new(Builders.pdf_bytes), info)

      expect(result.markdown).to include("Hello PDF")
    end
  end

  describe Markdownator::Converters::Epub do
    it "converts spine chapters via the HTML converter and reads the title" do
      result = convert(Builders.epub_bytes, "epub")

      expect(result.title).to eq("My Book")
      expect(result.markdown).to include("# Chapter One")
      expect(result.markdown).to include("It was a dark and stormy night.")
    end
  end
end
