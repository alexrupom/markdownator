# frozen_string_literal: true

RSpec.describe Markdownator::Converters::Image do
  def convert(bytes, **opts)
    info = Markdownator::StreamInfo.new(extension: "jpg", filename: "photo.jpg")
    Markdownator.convert_stream(StringIO.new(bytes), info, **opts)
  end

  it "emits the filename as a heading" do
    expect(convert("bytes").markdown).to start_with("# photo.jpg")
  end

  it "appends a caption when a captioner is supplied" do
    captioner = Class.new do
      def caption(_io, _info)
        "A bicycle leaning on a wall."
      end
    end.new

    expect(convert("bytes", captioner: captioner).markdown)
      .to include("A bicycle leaning on a wall.")
  end

  it "ignores a captioner that returns blank text" do
    captioner = Class.new do
      def caption(_io, _info)
        "  "
      end
    end.new

    expect(convert("bytes", captioner: captioner).markdown).to eq("# photo.jpg")
  end
end
