# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in markdownator.gemspec
gemspec

# Development and test tooling.
group :development, :test do
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 1.21"
end

# Optional format libraries. These are NOT dependencies of the gem — each
# converter requires its gem lazily at runtime, and applications install only
# the ones for the formats they use. They are grouped here purely so the test
# suite can exercise every converter.
group :optional do
  gem "exifr", "~> 1.3"
  gem "nokogiri", "~> 1.15"
  gem "pdf-reader", "~> 2.12"
  gem "rubyzip", "~> 2.3"
end
