# frozen_string_literal: true

require_relative "lib/calltally/version"

Gem::Specification.new do |spec|
  spec.name = "calltally"
  spec.version = Calltally::VERSION
  spec.authors = ["Naoki Nishiguchi"]

  spec.summary = "Tally your method calls"
  spec.description  = "A simple yet powerful tool to analyze method usage in Ruby/Rails codebases. "\
                      "Track which methods are called most frequently, filter by receivers or method names, "\
                      "and export results in table, JSON, or CSV format. Perfect for understanding code patterns, "\
                      "refactoring decisions, and identifying heavily-used APIs."
  spec.homepage = "https://github.com/nsgc/calltally"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nsgc/calltally.git"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies for compatibility across Ruby versions
  spec.add_dependency "prism", ">= 1.0"  # Needed for Ruby 3.2, built-in for 3.3+
  spec.add_dependency "csv", ">= 3.0"    # No longer bundled with Ruby 3.4+

  spec.add_development_dependency "rake", "~> 13.0"
end
