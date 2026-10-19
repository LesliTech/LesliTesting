# frozen_string_literal: true

require "stringio"
require_relative "test_helper"

class CliReporterTest < Minitest::Test
    def setup
        super
        @reporter = LesliTesting::Reporters::CliReporter.new(StringIO.new, {})
    end

    def test_formats_collection_failures_with_supported_termline_styles
        message = "Expected 5 elements, found 2"

        formatted = @reporter.send(:parse_minitest_assertion_messages, message)

        assert_includes formatted, Termline::Style.icon(:info)
        assert_includes formatted, message
    end

    def test_formats_unknown_messages_with_supported_termline_styles
        message = "RuntimeError: original diagnostic"

        formatted = @reporter.send(:parse_minitest_assertion_messages, message)

        assert_includes formatted, Termline::Style.icon(:debug)
        assert_includes formatted, message
    end
end
