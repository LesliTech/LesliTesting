# Loading Lesli custom reporter for minitest
require "lesli_testing/minitest/cli_reporter"

module Minitest
    def self.plugin_lesli_testing_options(opts, options)
    end

    def self.plugin_lesli_testing_init(options)
        reporter.reporters.clear if reporter.respond_to?(:reporters)
        reporter_options = options.merge(
            lesli_testing_profile: LesliTesting.profile,
            lesli_testing_project_name: LesliTesting.app_name
        )
        reporter << LesliTesting::Reporters::CliReporter.new(options[:io] || $stdout, reporter_options)
    end
end
