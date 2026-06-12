# frozen_string_literal: true

RSpec.describe Markdownator::Engine do
  subject(:engine) { described_class.new }

  describe "#convert_stream dispatch" do
    it "routes to the converter matching the extension" do
      io = StringIO.new("a,b\n1,2")
      info = Markdownator::StreamInfo.new(extension: "csv")

      expect(engine.convert_stream(io, info).markdown).to include("| a | b |")
    end

    it "falls back to mimetype when no extension is given" do
      io = StringIO.new("plain text body")
      info = Markdownator::StreamInfo.new(mimetype: "text/plain")

      expect(engine.convert_stream(io, info).markdown).to eq("plain text body")
    end

    it "raises UnsupportedFormatError when nothing accepts the stream" do
      io = StringIO.new("data")
      info = Markdownator::StreamInfo.new(extension: "unknownext")

      expect { engine.convert_stream(io, info) }
        .to raise_error(Markdownator::UnsupportedFormatError)
    end
  end

  describe "stream rewinding" do
    it "presents a rewound stream to the chosen converter" do
      io = StringIO.new("a,b\n1,2")
      io.read # exhaust the stream before conversion

      info = Markdownator::StreamInfo.new(extension: "csv")

      expect(engine.convert_stream(io, info).markdown).to include("| 1 | 2 |")
    end
  end

  describe "custom converter chains" do
    it "uses the provided converters instead of the defaults" do
      stub = Class.new(Markdownator::Converters::Base) do
        def accepts?(_io, _info)
          true
        end

        def convert(_io, _info, **_opts)
          Markdownator::Result.new(markdown: "stubbed")
        end
      end

      custom = described_class.new(converters: [stub.new])
      expect(custom.convert_stream(StringIO.new("x")).markdown).to eq("stubbed")
    end
  end
end
