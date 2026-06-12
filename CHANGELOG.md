# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/alexrupom/markdownator/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/alexrupom/markdownator/releases/tag/v0.1.0
