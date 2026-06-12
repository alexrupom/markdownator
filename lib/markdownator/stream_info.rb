# frozen_string_literal: true

module Markdownator
  # Immutable value object describing a stream of bytes to be converted.
  #
  # It carries the hints (extension, mimetype, charset, filename, url,
  # local_path) that converters use to decide whether they can handle a given
  # input.
  class StreamInfo
    # Maps a lower-case file extension (without the dot) to a mimetype.
    EXTENSION_TO_MIMETYPE = {
      "txt" => "text/plain",
      "text" => "text/plain",
      "md" => "text/markdown",
      "markdown" => "text/markdown",
      "html" => "text/html",
      "htm" => "text/html",
      "csv" => "text/csv",
      "json" => "application/json",
      "xml" => "application/xml",
      "pdf" => "application/pdf",
      "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "epub" => "application/epub+zip",
      "zip" => "application/zip",
      "jpg" => "image/jpeg",
      "jpeg" => "image/jpeg",
      "png" => "image/png",
      "gif" => "image/gif",
      "tif" => "image/tiff",
      "tiff" => "image/tiff"
    }.freeze

    attr_reader :mimetype, :extension, :charset, :filename, :url, :local_path

    def initialize(mimetype: nil, extension: nil, charset: nil, filename: nil, url: nil, local_path: nil)
      @mimetype = mimetype
      @extension = normalize_extension(extension)
      @charset = charset
      @filename = filename
      @url = url
      @local_path = local_path
      freeze
    end

    # Returns a new StreamInfo with the given attributes overridden, filling in
    # any attribute not provided from the current instance.
    def copy_with(**overrides)
      self.class.new(
        mimetype: overrides.fetch(:mimetype, mimetype),
        extension: overrides.fetch(:extension, extension),
        charset: overrides.fetch(:charset, charset),
        filename: overrides.fetch(:filename, filename),
        url: overrides.fetch(:url, url),
        local_path: overrides.fetch(:local_path, local_path)
      )
    end

    # Best-effort mimetype: the explicit one, otherwise derived from extension.
    def guessed_mimetype
      mimetype || EXTENSION_TO_MIMETYPE[extension]
    end

    private

    def normalize_extension(ext)
      return nil if ext.nil? || ext.empty?

      ext.to_s.downcase.delete_prefix(".")
    end
  end
end
