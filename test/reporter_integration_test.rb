# frozen_string_literal: true

require "open3"
require "rbconfig"
require_relative "test_helper"

class ReporterIntegrationTest < Minitest::Test
    PROJECT_ROOT = File.expand_path("..", __dir__)
    LIB_PATH = File.join(PROJECT_ROOT, "lib")

    def test_successful_test_output_and_exit_code
        output, status = run_suite(<<~RUBY)
            def test_success
                assert_equal 2, 1 + 1
            end
        RUBY

        assert_equal 0, status.exitstatus, output
        assert_includes output, "PASS"
        assert_includes output, "ReporterScenarioTest"
        assert_includes output, "test_success"
        assert_includes output, "Test suite passed"
    end

    def test_failure_output_and_exit_code
        output, status = run_suite(<<~RUBY)
            def test_failure
                assert_equal 1, 2
            end
        RUBY

        assert_equal 1, status.exitstatus, output
        assert_includes output, "FAIL"
        assert_includes output, "FAILURE"
        assert_includes output, "Expected: 1"
        assert_includes output, "Actual: 2"
        assert_includes output, "Test suite failed"
    end

    def test_unexpected_exception_output_and_exit_code
        output, status = run_suite(<<~RUBY)
            def test_unexpected_exception
                raise "unexpected explosion"
            end
        RUBY

        assert_equal 1, status.exitstatus, output
        assert_includes output, "ERROR"
        assert_includes output, "RuntimeError"
        assert_includes output, "unexpected explosion"
        assert_includes output, "Test suite failed"
    end

    def test_skip_reason_output_and_exit_code
        output, status = run_suite(<<~RUBY)
            def test_skip
                skip "requires PostgreSQL"
            end
        RUBY

        assert_equal 0, status.exitstatus, output
        assert_includes output, "SKIP"
        assert_includes output, "Reason: requires PostgreSQL"
        assert_includes output, "Test suite passed"
    end

    def test_warning_output_and_exit_code
        output, status = run_suite(<<~RUBY, arguments: ["-Werror"])
            def test_warning
                warn "deprecated endpoint"
            end
        RUBY

        assert_equal 1, status.exitstatus, output
        assert_includes output, "WARN"
        assert_includes output, "WARNING"
        assert_includes output, "deprecated endpoint"
        assert_includes output, "Test suite failed"
    end

    def test_quiet_mode_hides_individual_results_but_keeps_summary_and_exit_code
        output, status = run_suite(
            <<~RUBY,
                def test_quiet_success
                    assert true
                end
            RUBY
            environment: { "QUIET" => "true" }
        )

        assert_equal 0, status.exitstatus, output
        refute_includes output, "test_quiet_success"
        assert_includes output, "TESTS. . . . . . . . :"
        assert_includes output, "Test suite passed"
    end

    def test_filter_without_results_explains_failure_and_returns_nonzero
        output, status = run_suite(
            <<~RUBY,
                def test_exists
                    assert true
                end
            RUBY
            arguments: ["--name", "/NOT_FOUND/"]
        )

        assert_equal 1, status.exitstatus, output
        assert_includes output, "No tests matched filter: /NOT_FOUND/"
        assert_includes output, "Nothing ran for filter: /NOT_FOUND/"
    end

    def test_external_reporter_is_removed_before_the_suite_runs
        script = <<~RUBY
            require "lesli_testing"
            require "minitest"

            class ExternalReporter < Minitest::AbstractReporter
                def record(result)
                    puts "EXTERNAL REPORTER: \#{result.name}"
                end
            end

            module Minitest
                def self.plugin_external_options(_opts, _options)
                end

                def self.plugin_external_init(_options)
                    reporter << ExternalReporter.new
                end
            end

            Minitest.register_plugin("external")
            LesliTesting.gem("ReporterIntegration")
            require "minitest/autorun"

            class ReporterScenarioTest < Minitest::Test
                def test_success
                    assert true
                end
            end
        RUBY

        output, status = run_script(script)

        assert_equal 0, status.exitstatus, output
        assert_includes output, "PASS"
        assert_includes output, "test_success"
        refute_includes output, "EXTERNAL REPORTER"
    end

    def test_string_difference_output_and_exit_code
        output, status = run_suite(<<~'RUBY')
            def test_string_difference
                expected = "alpha\nshared\nomega\n"
                actual = "alpha\nchanged\nomega\n"

                assert_equal expected, actual
            end
        RUBY

        assert_equal 1, status.exitstatus, output
        assert_includes output, "--- expected"
        assert_includes output, "+++ actual"
        assert_includes output, "-shared"
        assert_includes output, "+changed"
    end

    def test_collection_difference_output_and_exit_code
        output, status = run_suite(<<~RUBY)
            def test_collection_difference
                assert_equal [:alpha, :beta], [:alpha, :gamma]
            end
        RUBY

        assert_equal 1, status.exitstatus, output
        assert_includes output, "Expected: [:alpha, :beta]"
        assert_includes output, "Actual: [:alpha, :gamma]"
    end

    private

    def run_suite(test_source, environment: {}, arguments: [])
        run_script(
            <<~RUBY,
                require "lesli_testing"
                LesliTesting.gem("ReporterIntegration")
                require "minitest/autorun"

                class ReporterScenarioTest < Minitest::Test
                #{test_source}
                end
            RUBY
            environment: environment,
            arguments: arguments
        )
    end

    def run_script(script, environment: {}, arguments: [])
        stdout, stderr, status = Open3.capture3(
            { "COVERAGE" => nil, "QUIET" => nil }.merge(environment),
            RbConfig.ruby,
            "-I#{LIB_PATH}",
            "-e",
            script,
            "--",
            *arguments,
            chdir: PROJECT_ROOT
        )

        [[stdout, stderr].reject(&:empty?).join("\n"), status]
    end
end
