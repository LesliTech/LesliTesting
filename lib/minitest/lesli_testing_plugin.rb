# Loading Lesli custom reporter for minitest
require "lesli_testing/minitest/cli_reporter"

module Minitest
    def self.plugin_lesli_testing_options(opts, options)
    end

    def self.plugin_lesli_testing_init(options)
        reporter.reporters.clear if reporter.respond_to?(:reporters)
        reporter << LesliTesting::Reporters::CliReporter.new($stdout, options)
    end
end
