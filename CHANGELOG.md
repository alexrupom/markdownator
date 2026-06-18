# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `nokogiri`, `rubyzip`, `pdf-reader`, and `exifr` are now runtime dependencies,
  so every supported format works out of the box instead of requiring callers to
  install the format gems themselves.

## [0.1.2] - 2026-06-13

### Changed

- XLSX conversion now reads the workbook directly with rubyzip and Nokogiri
  instead of `roo`, so every Office format (DOCX, XLSX, PPTX, EPUB) shares one
  approach and the `roo` dependency is dropped.
- Moved the HTML renderer to `Markdownator::Renderers::HtmlRenderer` (it renders
  Markdown, it does not convert a source file).

## [0.1.1] - 2026-06-13

### Changed

- HTML (and EPUB) conversion now renders Markdown directly from the Nokogiri
  node tree, dropping the `reverse_markdown` dependency (it was only a thin
  layer over Nokogiri).

## [0.1.0] - 2026-06-12

### Added

- Converter-registry engine (`Markdownator.convert`, `.convert_local`,
  `.convert_stream`) dispatching local paths, URLs, and IO streams to the first
  converter that accepts the stream.
- Converters for plain text, HTML, CSV, JSON, XML, DOCX, XLSX, PPTX, PDF, EPUB,
  ZIP (recursive), and image metadata.
- Optional, lazily loaded format dependencies with a helpful
  `MissingDependencyError` when a required gem is absent; zero hard runtime
  dependencies.
- Pluggable LLM image-captioner hook (off by default).

[Unreleased]: https://github.com/alexrupom/markdownator/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/alexrupom/markdownator/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/alexrupom/markdownator/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/alexrupom/markdownator/releases/tag/v0.1.0
