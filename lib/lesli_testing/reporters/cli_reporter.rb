
# lib/lesli_testing/reporters/cli_reporter.rb
require "minitest"

module LesliTesting
    module Reporters
        class CliReporter < Minitest::StatisticsReporter
            def start
                super
                Termline.m(
                    Termline::Style.colorize(" Running Lesli tests...", :blue),
                    Termline::Style.colorize(" -> For a better result run test over a clean database", :blue),
                    Termline::Style.colorize(" -> You can use: rake dev:db:reset", :blue)
                )
                Termline.br
            end

            def record(test)
                super

                assert_color = :green
                assert_color = :yellow if test.assertions < 5
                assert_color = :red if test.assertions < 2

                parts = []
                parts << Termline::Style.colorize('['+Time.now.strftime('%H:%M:%S:%L')+']', :gray)
                
                case test.result_code
                when "."
                    parts << Termline::Style.colorize("PASS", :green)
                when "F"
                    parts << Termline::Style.colorize("FAIL", :red)
                when "E"
                    parts << Termline::Style.colorize("ERROR", :red)
                when "S"
                    parts << Termline::Style.colorize("SKIP", :yellow)
                end

                parts << '::'
                parts << Termline::Style.colorize(test.klass, :blue)
                parts << '->'
                parts << Termline::Style.colorize(test.name, :skyblue)
                parts << Termline::Style.colorize("(#{ test.assertions} asserts)", assert_color) 
                parts << Termline::Style.colorize("#{"(%.2fs)" % test.time}", :red) if test.time > 1 

                puts(parts.compact.join(" ").strip)
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

                Termline.br 2

                status_color = :blue
                status_color = :red if status == 'FAIL'

                failures_color = :blue
                failures_color = :red if total_failures > 0

                Termline::Msg.builder(status,                   tag:'STATUS . . . . . . . :', color: status_color, timestamp:nil)
                Termline::Msg.builder(total_tests,              tag:'TESTS. . . . . . . . :', color: :blue, timestamp:nil)
                Termline::Msg.builder(passed,                   tag:'PASSED . . . . . . . :', color: :blue, timestamp:nil)
                Termline::Msg.builder(total_failures,           tag:'FAILURES . . . . . . :', color: failures_color, timestamp:nil)
                Termline::Msg.builder(total_errors,             tag:'ERRORS . . . . . . . :', color: :blue, timestamp:nil)
                Termline::Msg.builder(total_skips,              tag:'SKIPPED. . . . . . . :', color: :blue, timestamp:nil)
                Termline::Msg.builder(total_assertions,         tag:'ASSERTIONS . . . . . :', color: :blue, timestamp:nil)
                Termline::Msg.builder("#{success_rate}%",       tag:'SUCCESS RATE . . . . :', color: failures_color, timestamp:nil)
                Termline::Msg.builder(format("%.2fs", duration),tag:'TIME . . . . . . . . :', color: :blue, timestamp:nil)

                Termline.br 2

                if status == "PASS"
                    Termline.success("Test suite passed")
                else
                    Termline.danger("Test suite failed", tag:'FAILURE')
                end

                Termline.br

                print_failure_details if total_failures.positive? || total_errors.positive?

            end

            private

            def print_failure_details
                failed_results = Array(results).select { |result| result.failure }

                return if failed_results.empty?

                failed_results.each_with_index do |result, index|
                    failure = result.failure
                    failure_tag = failure.is_a?(Minitest::Assertion) ? "FAILURE" : "ERROR"
                    failure_msg = "#{result.class}##{result.name} (#{result.assertions} asserts)"

                    Termline.br
                    Termline.line(6)
                    Termline.br

                    if failure.is_a?(Minitest::Assertion)
                        Termline::Msg.builder(failure_msg, tag: " #{Termline::Style.icon(:error)} #{failure_tag} #{index + 1}:", color: :red, timestamp:nil)
                        puts "    #{Termline::Style.colorize('Location:', :yellow)} #{result.source_location.first} (line: #{result.source_location.second})"
                        puts "    #{Termline::Style.colorize(result.failure.message.to_s.lines.first.strip, :green)}"
                        puts "      #{Termline::Style.colorize(result.failure.message.to_s.lines.second.strip, :red)}"
                    else
                        Termline.warning(failure_msg, tag: failure_tag)
                    end
                end

                Termline.br
            end
        end
    end
end
