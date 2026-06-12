# frozen_string_literal: true

module Markdownator
  # The result of a conversion: the produced Markdown plus optional metadata.
  #
  # `#to_s` and `#text_content` both return the Markdown so the result is
  # convenient to print or interpolate.
  class Result
    attr_reader :markdown, :title, :metadata

    def initialize(markdown:, title: nil, metadata: {})
      @markdown = markdown.to_s
      @title = title
      @metadata = metadata || {}
    end

    def to_s
      markdown
    end

    alias text_content markdown
  end
end
