
# lib/lesli_testing/reporters/cli_reporter.rb
require "minitest"

module LesliTesting
    module Reporters
        class CliReporter < Minitest::StatisticsReporter
            def start
                super
                Termline::Msg.builder("Running Lesli tests...", tag: nil, color: :blue)
                Termline::Msg.builder("For a better result run test over a clean database", tag: nil, color: :blue)
                Termline::Msg.builder("You can use: rake dev:db:reset", tag: nil, color: :blue)
                Termline.br
            end

            def record(test)
                super

                #name = "#{test.klass}# -> #{test.name}: with #{test.assertions} asserts"
                name = "#{test.klass}# -> #{test.name}"

                case test.result_code
                when "."
                    puts("#{Termline::Config.colorize("PASS", :green)} :: #{Termline::Config.colorize(test.klass, :blue)} -> #{Termline::Config.colorize(test.name, :skyblue)}")
                    ## show asserts amount only if it is to low
                    ## show time if it is to hight
                    # example:
                        # PASS :: Controller -> method (1 assertions.yellow)
                        # PASS :: Controller -> method (30 seconds.yellow)
                    ###{test.assertions} assertions in #{"(%.2fs)" % test.time} for
                when "F"
                    Termline::Msg.builder(name, tag: "FAIL:", color: :red)
                when "E"
                    Termline::Msg.builder(name, tag: "ERROR:", color: :red)
                when "S"
                    Termline::Msg.builder(name, tag: "SKIP:", color: :yellow)
                end
            end

            def report
                super

                total_tests = count.to_i
                total_failures = failures.to_i
                total_errors = errors.to_i
                total_skips = skips.to_i
                total_assertions = assertions.to_i
                duration = total_time.to_f

                passed = total_tests - total_failures - total_errors - total_skips
                success_rate = total_tests.zero? ? 0 : ((passed.to_f / total_tests) * 100).round(1)
                status = (total_failures.zero? && total_errors.zero?) ? "PASS" : "FAIL"

                Termline.br

                Termline::Msg.builder(status,                   tag:'STATUS . . . . . . . :', color: :blue)
                Termline::Msg.builder(total_tests,              tag:'TESTS. . . . . . . . :', color: :blue)
                Termline::Msg.builder(passed,                   tag:'PASSED . . . . . . . :', color: :blue)
                Termline::Msg.builder(total_failures,           tag:'FAILURES . . . . . . :', color: :blue)
                Termline::Msg.builder(total_errors,             tag:'ERRORS . . . . . . . :', color: :blue)
                Termline::Msg.builder(total_skips,              tag:'SKIPPED. . . . . . . :', color: :blue)
                Termline::Msg.builder(total_assertions,         tag:'ASSERTIONS . . . . . :', color: :blue)
                Termline::Msg.builder("#{success_rate}%",       tag:'SUCCESS RATE . . . . :', color: :blue)
                Termline::Msg.builder(format("%.2fs", duration),tag:'TIME . . . . . . . . :', color: :blue)

                Termline.br

                if status == "PASS"
                    Termline.success("Test suite passed")
                else
                    Termline.error("Test suite failed")
                end

                Termline.br

                print_failure_details if total_failures.positive? || total_errors.positive?

            end

            private

            def print_failure_details
                failed_results = Array(results).select { |result| result.failure }

                return if failed_results.empty?

                puts
                Termline.danger("Failure Details")

                failed_results.each_with_index do |result, index|
                    failure = result.failure
                    label = failure.is_a?(Minitest::Assertion) ? "FAILURE" : "ERROR"
                    title = "#{index + 1}) #{label} - #{result.class}##{result.name}"

                    if failure.is_a?(Minitest::Assertion)
                    Termline.error(title)
                    else
                    Termline.warning(title)
                    end

                    first_line = failure.message.to_s.lines.first.to_s.strip
                    puts "  Message: #{first_line}"

                    if failure.backtrace&.any?
                    puts "  Source:  #{failure.backtrace.first}"
                    end

                    puts
                end
            end
        end
    end
end
