# frozen_string_literal: true

require "stringio"
require "uri"
require "net/http"

module Markdownator
  # Orchestrator that holds an ordered list of converters and dispatches an
  # input (local path, URL, or IO stream) to the first converter that accepts it.
  class Engine
    # Default converters, in priority order. More specific formats (the
    # ZIP-based Office/EPUB containers) must come before the generic ZIP
    # converter, and the plain-text fallback comes last.
    DEFAULT_CONVERTER_ORDER = %i[
      docx xlsx pptx epub zip pdf image html csv json xml plain_text
    ].freeze

    attr_reader :converters

    # @param converters [Array<Converters::Base>] custom converter chain.
    # @param options [Hash] default options threaded into every conversion
    #   (e.g. `captioner:`).
    def initialize(converters: nil, **options)
      @converters = converters || self.class.default_converters
      @default_options = options
    end

    def self.default_converters
      DEFAULT_CONVERTER_ORDER.map do |name|
        Converters.const_get(camelize(name)).new
      end
    end

    def self.camelize(name)
      name.to_s.split("_").map(&:capitalize).join
    end

    # Permissive entry point: dispatches based on what `source` looks like.
    def convert(source, **options)
      if source.respond_to?(:read)
        convert_stream(source, options.delete(:stream_info), **options)
      elsif url?(source)
        convert_url(source, **options)
      else
        convert_local(source, **options)
      end
    end

    # Converts a local file path.
    def convert_local(path, **options)
      raise FileConversionError, "No such file: #{path}" unless File.file?(path)

      stream_info = StreamInfo.new(
        extension: File.extname(path),
        filename: File.basename(path),
        local_path: path
      )
      File.open(path, "rb") do |io|
        convert_stream(io, stream_info, **options)
      end
    end

    # Fetches an http(s) URL and converts the response body.
    def convert_url(url, **options)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      raise FileConversionError, "HTTP #{response.code} fetching #{url}" unless response.is_a?(Net::HTTPSuccess)

      stream_info = StreamInfo.new(
        mimetype: response.content_type,
        extension: File.extname(uri.path.to_s),
        charset: response.type_params["charset"],
        filename: File.basename(uri.path.to_s),
        url: url
      )
      convert_stream(StringIO.new(response.body), stream_info, **options)
    end

    # Converts an open IO stream. `stream_info` provides format hints.
    def convert_stream(io, stream_info = nil, **options)
      stream_info ||= StreamInfo.new
      opts = @default_options.merge(options)
      opts[:engine] = self

      converter = pick_converter(io, stream_info)
      raise UnsupportedFormatError, describe_unsupported(stream_info) if converter.nil?

      io.rewind if io.respond_to?(:rewind)
      converter.convert(io, stream_info, **opts)
    end

    private

    def pick_converter(io, stream_info)
      converters.find do |converter|
        io.rewind if io.respond_to?(:rewind)
        converter.accepts?(io, stream_info)
      end
    end

    def url?(source)
      source.is_a?(String) && source.match?(%r{\Ahttps?://}i)
    end

    def describe_unsupported(stream_info)
      hint = stream_info.filename || stream_info.url || stream_info.guessed_mimetype || "the given stream"
      "No converter accepted #{hint}"
    end
  end
end
