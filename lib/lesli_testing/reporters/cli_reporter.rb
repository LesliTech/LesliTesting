
# lib/lesli_testing/reporters/cli_reporter.rb
require "minitest"

module LesliTesting
    module Reporters
        class CliReporter < Minitest::StatisticsReporter
            def start
                super

                Termline.br

                Termline.m(
                    Termline::Style.colorize("Running Lesli tests...", :blue),
                    Termline::Style.colorize("-> For a better result run test over a clean database", :blue),
                    Termline::Style.colorize("-> You can use: rake dev:db:reset", :blue)
                )

                Termline.br 2
            end

            def record(test)
                super

                # Map result codes to styles
                status_map = { 
                    "." => [:green, "PASS"], 
                    "S" => [:yellow, "SKIP"], 
                    "E" => [:red, "ERROR"], 
                    "F" => [:red, "FAIL"]
                }
                color, label = status_map[test.result_code] || [:gray, "????"]

                # Determine assertion health
                assert_color = case test.assertions
                    when 0..1 then :red
                    when 2..4 then :yellow
                    else :green
                end

                parts = [
                    Termline::Style.colorize("[#{Time.now.strftime('%H:%M:%S')}]", :gray),
                    Termline::Style.colorize(label, color),
                    "::",
                    Termline::Style.colorize(test.klass, :blue),
                    "->",
                    Termline::Style.colorize(test.name, :skyblue),
                    Termline::Style.colorize("(#{test.assertions} asserts)", assert_color)
                ]

                # Add execution time per test
                parts << Termline::Style.colorize("(%.2fs)" % test.time, :red) if test.time > 1

                puts(parts.join(" "))
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

                puts(Termline::Msg.builder(status,                   tag:'STATUS . . . . . . . :', color: status_color, timestamp:nil))
                puts(Termline::Msg.builder(total_tests,              tag:'TESTS. . . . . . . . :', color: :blue, timestamp:nil))
                puts(Termline::Msg.builder(passed,                   tag:'PASSED . . . . . . . :', color: :blue, timestamp:nil))
                puts(Termline::Msg.builder(total_failures,           tag:'FAILURES . . . . . . :', color: failures_color, timestamp:nil))
                puts(Termline::Msg.builder(total_errors,             tag:'ERRORS . . . . . . . :', color: :blue, timestamp:nil))
                puts(Termline::Msg.builder(total_skips,              tag:'SKIPPED. . . . . . . :', color: :blue, timestamp:nil))
                puts(Termline::Msg.builder(total_assertions,         tag:'ASSERTIONS . . . . . :', color: :blue, timestamp:nil))
                puts(Termline::Msg.builder("#{success_rate}%",       tag:'SUCCESS RATE . . . . :', color: failures_color, timestamp:nil))
                puts(Termline::Msg.builder(format("%.2fs", duration),tag:'TIME . . . . . . . . :', color: :blue, timestamp:nil))

                Termline.br 2

                if status == "PASS"
                    Termline.success("Test suite passed")
                else
                    Termline.danger("Test suite failed", tag:'FAILURE')
                end

                Termline.br 2

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

                    file, line = result.source_location
                    location_file = file ? "#{file} (line: #{line})" : "Location unknown"

                    Termline.br
                    Termline.line(6)
                    Termline.br

                    puts Termline::Msg.builder(failure_msg, tag: " #{Termline::Style.icon(:error)} #{failure_tag} #{index + 1}:", color: :red, timestamp:nil)
                    puts Termline::Msg.builder(location_file, tag: " #{Termline::Style.icon(:debug)}  Location:", color: :yellow, timestamp:nil)

                    if failure.is_a?(Minitest::Assertion)
                        result.failure.message.to_s.lines.each do |message|
                            puts(parse_minitest_assertion_messages(message))
                            #puts(parse_minitest_assertion_messages2(message))
                        end
                    end
                end

                Termline.br
            end

            def parse_minitest_assertion_messages2 message
                msg = message.strip
                return Termline::Style.colorize(" +  #{msg}", :green) if msg.start_with? "Expected:"
                return Termline::Style.colorize(" -    #{msg}", :red) if msg.start_with? "Actual:"
                return Termline::Style.colorize(" #{Termline::Style.icon(:warning)}  #{msg}", :yellow)
            end

            def parse_minitest_assertion_messages(message)
            msg = message.strip

            case msg

                # 1. Boolean/Nil Failures (e.g., "Expected true to be nil" or "Expected false to be truthy")
                when /Expected (.*) to be (nil|truthy|falsey)/, /Expected (.*) to be (.*)/
                    Termline::Style.colorize(" #{Termline::Style.icon(:info)}  #{msg}", :skyblue)

                # 2. Standard Diffs (Expected vs Actual)
                when /^Expected:?\s+/
                    Termline::Style.colorize(" #{Termline::Style.icon(:add)}  #{msg}", :green)

                when /^Actual:?\s+/
                    Termline::Style.colorize(" #{Termline::Style.icon(:remove)}    #{msg}", :red)

                # 3. Rails Difference Failures (e.g., "User.count" didn't change by 1)
                when /"(.*)" didn't change by (.*)/, /actual change was (.*)/
                    Termline::Style.colorize(" #{Termline::Style.icon(:warning)}  #{msg}", :yellow)

                # 4. Collection/Count Failures (e.g., Expected 5 elements, found 2)
                when /Expected (.*) elements?, found (.*)/, /Expected exactly (.*) nodes/
                    Termline::Style.colorize(" #{Termline::Style.icon(:list)}  #{msg}", :magenta)

                # 5. Fallback for custom messages (anything else)
                else
                    Termline::Style.colorize(" #{Termline::Style.icon(:arrow_right)}  #{msg}", :gray)
                end
            end
        end
    end
end
