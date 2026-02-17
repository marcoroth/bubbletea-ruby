# frozen_string_literal: true

require_relative "lib/bubbletea/version"

Gem::Specification.new do |spec|
  spec.name = "bubbletea"
  spec.version = Bubbletea::VERSION
  spec.authors = ["Marco Roth"]
  spec.email = ["marco.roth@intergga.ch"]

  spec.summary = "Ruby wrapper for Charm's bubbletea. A powerful TUI framework."
  spec.description = "Build beautiful, interactive terminal applications using the Elm Architecture in Ruby."
  spec.homepage = "https://github.com/marcoroth/bubbletea-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "bubbletea.gemspec",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md",
    "sig/**/*.rbs",
    "lib/**/*.rb",
    "ext/**/*.{c,h,rb}",
    "go/**/*.{go,mod,sum}",
    "go/build/**/*"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/bubbletea/extconf.rb"]

  spec.add_dependency "lipgloss", "~> 0.1"
end
