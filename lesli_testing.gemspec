# frozen_string_literal: true

require_relative "lib/lesli_testing/version"

Gem::Specification.new do |spec|
    spec.name        = "lesli_testing"
    spec.version     = LesliTesting::VERSION
    spec.platform    = Gem::Platform::RUBY
    spec.license     = "GPL-3.0-or-later"
    spec.authors     = ["The Lesli Development Team"]
    spec.email       = ["hello@lesli.tech"]
    spec.homepage    = "https://www.lesli.dev/"
    spec.summary     = "Shared testing and coverage configuration for the Lesli Platform."
    spec.description = <<~DESC
        Core testing utilities for the Lesli Platform, providing standardized Minitest configuration, 
        coverage setup, and shared testing conventions across engines and applications.
    DESC

    # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
    # to allow pushing to a single host or delete this section to allow pushing to any host.
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"]       = spec.homepage
    spec.metadata["changelog_uri"]      = "https://github.com/LesliTech/LesliTesting/releases"
    spec.metadata["source_code_uri"]    = "https://github.com/LesliTech/LesliTesting"
    spec.metadata["bug_tracker_uri"]    = "https://github.com/LesliTech/LesliTesting/issues"
    spec.metadata["documentation_uri"]  = "https://www.lesli.dev/gems/testing/"

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


    # Create customizable MiniTest output formats. 
    # https://github.com/minitest-reporters/minitest-reporters
    spec.add_dependency "minitest-reporters"

    # Beautiful Minitest Color Reporter 
    # https://github.com/danielpclark/color_pound_spec_reporter
    spec.add_dependency "color_pound_spec_reporter"

    # Code coverage
    # https://github.com/simplecov-ruby/simplecov
    spec.add_dependency "simplecov", "0.22.0"

    # Code coverage stats in the console
    # https://github.com/chetan/simplecov-console
    spec.add_dependency "simplecov-console", "0.9.4"

    # Produces Cobertura XML formatted output from SimpleCov
    # https://github.com/jessebs/simplecov-cobertura
    spec.add_dependency "simplecov-cobertura"

    # Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis.
    # https://github.com/presidentbeef/brakeman
    spec.add_dependency "brakeman"

    # Until a patch for Rails 8.1.2 (or higher) is released specifically addressing the Minitest 6 boot sequence, the most stable way to run your tests is:
    #     Keep Minitest at ~> 5.0 in your Gemfile.
    #     Use the standard command: bin/rails test.
    spec.add_dependency "minitest", "~> 5.0"

    spec.add_dependency "letter_opener"

    spec.add_dependency "propshaft"
end
