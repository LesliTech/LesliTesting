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
    spec.files = Dir.chdir(File.expand_path(__dir__)) do
        Dir["{lib}/**/*", "license", "readme.md"]
    end
    
    spec.bindir = "exe"
    spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
    spec.require_paths = ["lib"]


    # Until a patch for Rails 8.1.2 (or higher) is released specifically addressing the Minitest 6 boot sequence, the most stable way to run your tests is:
    #     Keep Minitest at ~> 5.0 in your Gemfile.
    #     Use the standard command: bin/rails test.
    spec.add_dependency "minitest", "~> 6.0.0"

    # Code coverage
    # https://github.com/simplecov-ruby/simplecov
    spec.add_dependency "simplecov", "~> 0.22.0"

    # Code coverage stats in the console
    # https://github.com/chetan/simplecov-console
    spec.add_dependency "simplecov-console", "~> 0.9.0"

    # Produces Cobertura XML formatted output from SimpleCov
    # https://github.com/jessebs/simplecov-cobertura
    spec.add_dependency "simplecov-cobertura", "~> 3.1.0"

    # Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis.
    # https://github.com/presidentbeef/brakeman
    spec.add_dependency "brakeman", "~> 8.0.0"

    # When mail is sent from your application, Letter Opener will 
    # open a preview in the browser instead of sending.
    # https://github.com/ryanb/letter_opener
    spec.add_dependency "letter_opener", "~> 1.10.0"


    # Termline is a lightweight Ruby gem for printing terminal 
    # messages with colors, icons, and semantic log levels.
    # https://github.com/LesliTech/Termline
    spec.add_dependency "termline", "~> 1.1.0"

end
