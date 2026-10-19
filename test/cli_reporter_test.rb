# frozen_string_literal: true

require "stringio"
require "open3"
require "rbconfig"
require_relative "test_helper"

class CliReporterTest < Minitest::Test
    PROJECT_ROOT = File.expand_path("..", __dir__)
    LIB_PATH = File.join(PROJECT_ROOT, "lib")

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

    def test_is_a_summary_reporter_so_minitest_can_detect_empty_filtered_runs
        assert_kind_of Minitest::SummaryReporter, @reporter
    end

    def test_plugin_removes_all_other_reporters
        output = StringIO.new
        external_reporter = Minitest::AbstractReporter.new
        composite = Minitest::CompositeReporter.new(
            Minitest::SummaryReporter.new(output, {}),
            Minitest::ProgressReporter.new(output, {}),
            external_reporter
        )
        Minitest.reporter = composite

        Minitest.plugin_lesli_testing_init(io: output)

        assert_equal 1, composite.reporters.size
        assert_instance_of LesliTesting::Reporters::CliReporter, composite.reporters.first
        refute_includes composite.reporters, external_reporter
    ensure
        Minitest.reporter = nil
    end

    def test_filter_without_matching_tests_exits_with_an_explanation
        script = <<~RUBY
            require "lesli_testing"
            LesliTesting.gem("ExampleGem")
            require "minitest/autorun"

            class ExampleTest < Minitest::Test
                def test_exists
                    assert true
                end
            end
        RUBY

        stdout, stderr, status = Open3.capture3(
            { "COVERAGE" => nil },
            RbConfig.ruby,
            "-I#{LIB_PATH}",
            "-e",
            script,
            "--",
            "--name",
            "/NOT_FOUND/",
            chdir: PROJECT_ROOT
        )
        output = [stdout, stderr].join("\n")

        refute status.success?, output
        assert_includes output, "No tests matched filter: /NOT_FOUND/"
        assert_includes output, "Nothing ran for filter: /NOT_FOUND/"
    end
end
