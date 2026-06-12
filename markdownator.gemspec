# frozen_string_literal: true

require_relative "lib/markdownator/version"

Gem::Specification.new do |spec|
  spec.name = "markdownator"
  spec.version = Markdownator::VERSION
  spec.authors = ["alexrupom"]
  spec.email = ["alexrupom@hotmail.com"]

  spec.summary = "Convert files (Office docs, PDF, HTML, data, archives, images) to LLM-friendly Markdown."
  spec.description = "Markdownator converts PDF, Word, Excel, PowerPoint, EPUB, HTML, CSV, JSON, XML, " \
                     "ZIP archives and images into clean Markdown suitable for large language models, " \
                     "using a pluggable converter architecture."
  spec.homepage = "https://github.com/alexrupom/markdownator"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Heavy format gems are intentionally NOT runtime dependencies. Each converter
  # requires its gem lazily and raises a helpful error if it is missing, so apps
  # install only what they need. The gems used to exercise every format in the
  # test suite are declared as development dependencies in the Gemfile.
end
