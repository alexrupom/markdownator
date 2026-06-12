# frozen_string_literal: true

RSpec.describe Markdownator::Converters::Zip do
  def convert(bytes)
    info = Markdownator::StreamInfo.new(extension: "zip")
    Markdownator.convert_stream(StringIO.new(bytes), info)
  end

  it "recurses into each entry and concatenates results under file headings" do
    bytes = Builders.zip_bytes("a.csv" => "x,y\n1,2", "notes/b.txt" => "plain note")

    markdown = convert(bytes).markdown

    expect(markdown).to include("## a.csv")
    expect(markdown).to include("| x | y |")
    expect(markdown).to include("## notes/b.txt")
    expect(markdown).to include("plain note")
  end

  it "skips entries that cannot be converted" do
    bytes = Builders.zip_bytes("good.txt" => "keep me", "mystery.bin" => "\x00\x01\x02")

    markdown = convert(bytes).markdown

    expect(markdown).to include("## good.txt")
    expect(markdown).not_to include("mystery.bin")
  end
end
