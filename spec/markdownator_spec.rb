# frozen_string_literal: true

require "tempfile"

RSpec.describe Markdownator do
  it "has a version number" do
    expect(Markdownator::VERSION).not_to be_nil
  end

  describe ".convert" do
    it "converts a local file, detecting the format from its extension" do
      Tempfile.create(["sample", ".csv"]) do |file|
        file.write("name,age\nAlice,30")
        file.flush

        result = described_class.convert(file.path)

        expect(result).to be_a(Markdownator::Result)
        expect(result.markdown).to eq("| name | age |\n| --- | --- |\n| Alice | 30 |")
      end
    end

    it "raises FileConversionError for a missing file" do
      expect { described_class.convert("/no/such/file.csv") }
        .to raise_error(Markdownator::FileConversionError, /No such file/)
    end
  end

  describe ".convert_stream" do
    it "converts an IO using StreamInfo hints" do
      io = StringIO.new("# Title")
      info = Markdownator::StreamInfo.new(extension: "md")

      expect(described_class.convert_stream(io, info).markdown).to eq("# Title")
    end
  end

  describe ".require_optional" do
    it "raises a helpful MissingDependencyError when the gem is absent" do
      allow(described_class).to receive(:require).and_raise(LoadError)

      expect { described_class.require_optional("nope", feature: "Testing") }
        .to raise_error(Markdownator::MissingDependencyError, /Testing requires the 'nope' gem/)
    end
  end
end
