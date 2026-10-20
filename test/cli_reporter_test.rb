# frozen_string_literal: true

require "stringio"
require_relative "test_helper"

class CliReporterTest < Minitest::Test
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

    def test_formats_boolean_and_nil_failures
        message = "Expected true to be nil"

        formatted = @reporter.send(:parse_minitest_assertion_messages, message)

        assert_equal Termline::Style.colorize(" #{Termline::Style.icon(:info)}  #{message}", :skyblue), formatted
    end

    def test_formats_expected_and_actual_lines
        expected = @reporter.send(:parse_minitest_assertion_messages, "Expected: 1")
        actual = @reporter.send(:parse_minitest_assertion_messages, "Actual: 2")

        assert_equal Termline::Style.colorize(" #{Termline::Style.icon(:add)}  Expected: 1", :green), expected
        assert_equal Termline::Style.colorize(" #{Termline::Style.icon(:remove)}    Actual: 2", :red), actual
    end

    def test_formats_rails_difference_messages_without_loading_rails
        missing_change = %q{"User.count" didn't change by 1}
        actual_change = "actual change was 0"

        [missing_change, actual_change].each do |message|
            formatted = @reporter.send(:parse_minitest_assertion_messages, message)

            assert_equal Termline::Style.colorize(" #{Termline::Style.icon(:warning)}  #{message}", :yellow), formatted
        end
    end

    def test_formats_unknown_messages_with_supported_termline_styles
        message = "RuntimeError: original diagnostic"

        formatted = @reporter.send(:parse_minitest_assertion_messages, message)

        assert_includes formatted, Termline::Style.icon(:debug)
        assert_includes formatted, message
    end

    def test_formats_unified_diff_headers_without_duplicating_plus_signs
        removed_header = @reporter.send(:parse_minitest_assertion_messages, "--- expected")
        header = @reporter.send(:parse_minitest_assertion_messages, "+++ actual")
        hunk = @reporter.send(:parse_minitest_assertion_messages, "@@ -1 +1 @@")
        removed_line = @reporter.send(:parse_minitest_assertion_messages, "-removed")
        added_line = @reporter.send(:parse_minitest_assertion_messages, "+added")

        assert_equal Termline::Style.colorize("--- expected", :red), removed_header
        assert_equal Termline::Style.colorize("+++ actual", :green), header
        assert_equal Termline::Style.colorize("@@ -1 +1 @@", :skyblue), hunk
        assert_equal Termline::Style.colorize(" - -removed", :red), removed_line
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

    def test_application_header_includes_database_guidance
        output = render_header("app", "ExampleApp")

        assert_includes output, "Running tests for ExampleApp (Rails application)..."
        assert_includes output, "clean database"
        assert_includes output, "rake dev:db:rebuild"
    end

    def test_engine_header_uses_rails_test_application_guidance
        output = render_header("engine", "ExampleEngine")

        assert_includes output, "Running tests for ExampleEngine (Rails engine)..."
        assert_includes output, "engine's Rails test application"
        refute_includes output, "rake dev:db:rebuild"
    end

    def test_gem_header_omits_rails_and_database_guidance
        output = render_header("gem", "ExampleGem")

        assert_includes output, "Running tests for ExampleGem (Ruby gem)..."
        refute_match(/Rails|database|rake dev:db:rebuild/i, output)
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
        assert_includes output, "WARNINGS . . . . . . :"
        assert_includes output, "WARNING"
        assert_includes output, "deprecated API"
        assert_includes output, "Reason: requires PostgreSQL"
        assert_includes output, "STATUS . . . . . . . :"
        assert_includes output, "FAIL"
    end

    def test_is_a_summary_reporter_so_minitest_can_detect_empty_filtered_runs
        assert_kind_of Minitest::SummaryReporter, @reporter
    end

    def test_quiet_hides_results_only_for_explicit_true_values
        result = Minitest::Result.new("test_example")
        result.klass = "ExampleTest"
        result.assertions = 1
        result.time = 0.01

        %w[true 1 yes].each do |value|
            output = record_result(result, quiet: value)
            assert_empty output, value
        end

        %w[false 0 no].each do |value|
            output = record_result(result, quiet: value)
            assert_includes output, "test_example", value
        end
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
        assert_equal "gem", composite.reporters.first.options[:lesli_testing_profile]
        assert_equal "LesliTesting", composite.reporters.first.options[:lesli_testing_project_name]
        refute_includes composite.reporters, external_reporter
    ensure
        Minitest.reporter = nil
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

    def render_header(profile, project_name)
        output = StringIO.new
        reporter = LesliTesting::Reporters::CliReporter.new(
            output,
            lesli_testing_profile: profile,
            lesli_testing_project_name: project_name
        )
        reporter.start
        output.string
    end

    def record_result(result, quiet:)
        output = StringIO.new
        reporter = LesliTesting::Reporters::CliReporter.new(output, {})
        previous = ENV["QUIET"]
        ENV["QUIET"] = quiet
        reporter.record(result)
        output.string
    ensure
        previous.nil? ? ENV.delete("QUIET") : ENV["QUIET"] = previous
    end
end
