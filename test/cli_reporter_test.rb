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
        @output = StringIO.new
        @reporter = LesliTesting::Reporters::CliReporter.new(@output, {})
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

    def test_formats_unified_diff_headers_without_duplicating_plus_signs
        header = @reporter.send(:parse_minitest_assertion_messages, "+++ actual")
        added_line = @reporter.send(:parse_minitest_assertion_messages, "+added")

        assert_equal Termline::Style.colorize("+++ actual", :green), header
        refute_includes header, "+++++ actual"
        assert_equal Termline::Style.colorize(" + +added", :green), added_line
        refute_includes added_line, "+++added"
    end

    def test_summary_omits_empty_timestamp_and_writes_only_to_reporter_io
        stdout, stderr = capture_io do
            @reporter.start
            @reporter.report
        end

        assert_empty stdout
        assert_empty stderr
        assert_includes @output.string, "STATUS . . . . . . . :"
        refute_includes @output.string, "[]"
    end

    def test_failure_details_use_original_class_and_failure_location
        failure = located_failure(Minitest::Assertion.new("Expected: 1\nActual: 2"), "/real/test/path.rb:42")
        result = build_result("OriginalTestClass", "test_example", failure)
        result.source_location = ["/wrong/source/location.rb", 7]

        output = render(result)

        assert_includes output, "OriginalTestClass#test_example"
        refute_includes output, "Minitest::Result#test_example"
        assert_includes output, "/real/test/path.rb (line: 42)"
        refute_includes output, "/wrong/source/location.rb"
    end

    def test_errors_warnings_and_skips_are_reported
        error = RuntimeError.new("database unavailable")
        error.set_backtrace(["/real/error_test.rb:18:in `test_error'"])

        results = [
            build_result("ErrorTest", "test_error", located_failure(Minitest::UnexpectedError.new(error), "/real/error_test.rb:18")),
            build_result("WarningTest", "test_warning", located_failure(Minitest::UnexpectedWarning.new("deprecated API"), "/real/warning_test.rb:23")),
            build_result("SkippedTest", "test_skip", located_failure(Minitest::Skip.new("requires PostgreSQL"), "/real/skip_test.rb:31"))
        ]

        output = render(*results)
        red_errors_row = Termline::Msg.builder(
            1,
            tag: "ERRORS . . . . . . . :",
            color: :red,
            time: false
        )

        assert_includes output, red_errors_row
        assert_includes output, "WARNINGS. . . . . . . :"
        assert_includes output, "WARNING"
        assert_includes output, "deprecated API"
        assert_includes output, "Reason: requires PostgreSQL"
        assert_includes output, "STATUS . . . . . . . :"
        assert_includes output, "FAIL"
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
        assert_same output, composite.reporters.first.io
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

    private

    def build_result(klass, name, failure)
        result = Minitest::Result.new(name)
        result.klass = klass
        result.assertions = 1
        result.time = 0.01
        result.failures << failure
        result
    end

    def located_failure(failure, location)
        failure.define_singleton_method(:location) { location }
        failure
    end

    def render(*results)
        @reporter.start
        results.each { |result| @reporter.record(result) }
        @reporter.report
        @output.string
    end
end
