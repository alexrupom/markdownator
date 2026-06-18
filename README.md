# Markdownator

Convert files into clean, LLM-friendly **Markdown**. Point Markdownator at a PDF,
Office document, web page, archive, or image and get Markdown back.

It uses a pluggable converter-registry architecture, and ships with everything it
needs — every supported format works out of the box.

## Supported formats

| Format | Extensions | Backed by |
|--------|------------|-----------|
| Plain text / Markdown | `.txt`, `.md` | stdlib |
| CSV | `.csv` | stdlib |
| JSON | `.json` | stdlib |
| HTML | `.html`, `.htm` | `nokogiri` |
| XML | `.xml` | `nokogiri` |
| Word | `.docx` | `rubyzip`, `nokogiri` |
| Excel | `.xlsx` | `rubyzip`, `nokogiri` |
| PowerPoint | `.pptx` | `rubyzip`, `nokogiri` |
| PDF | `.pdf` | `pdf-reader` |
| EPUB | `.epub` | `rubyzip`, `nokogiri` |
| ZIP (recurses) | `.zip` | `rubyzip` |
| Images (metadata) | `.jpg`, `.png`, `.tiff`, … | `exifr` |

These libraries (`nokogiri`, `rubyzip`, `pdf-reader`, `exifr`) are runtime
dependencies, so they are installed with the gem automatically.

## Installation

```ruby
gem "markdownator"
```

or:

```sh
gem install markdownator
```

## Usage

```ruby
require "markdownator"

# From a local path — format is detected from the extension.
result = Markdownator.convert("report.pdf")
puts result.markdown
puts result.title     # when the format exposes one (HTML, EPUB)
puts result.metadata  # e.g. { page_count: 12 } for PDF

# From a URL.
Markdownator.convert("https://example.com").markdown

# From an open stream — pass hints via StreamInfo.
File.open("data.csv", "rb") do |io|
  info = Markdownator::StreamInfo.new(extension: "csv")
  Markdownator.convert_stream(io, info).markdown
end
```

`Result#to_s` and `Result#text_content` both return the Markdown, so a result is
convenient to print or interpolate directly.

### Image captioning (optional)

Image conversion emits EXIF metadata by default. To add a natural-language
description, pass any object that responds to `#caption(io, stream_info)` and
returns a `String`:

```ruby
class ClaudeCaptioner
  def caption(io, stream_info)
    # Send io.read to your vision model (e.g. Claude) and return its description.
  end
end

Markdownator.convert("photo.jpg", captioner: ClaudeCaptioner.new).markdown
```

No LLM gem is bundled; the hook is off unless you provide a captioner.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`rake spec` to run the tests, or `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/alexrupom/markdownator.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Markdownator project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/alexrupom/markdownator/blob/main/CODE_OF_CONDUCT.md).
