=begin

Lesli

Copyright (c) 2026, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

module LesliTesting
    module Reporters
        # Inheriting from SummaryReporter is important even though LesliTesting
        # renders its own summary. Minitest uses this type to detect a filtered
        # run in which no tests matched and return a non-zero exit status.
        class CliReporter < Minitest::SummaryReporter
            def start
                run_statistics_reporter(:start)

                io.puts
                io.puts Termline::Style.colorize("Running Lesli tests...", :blue)
                io.puts Termline::Style.colorize("-> For a better result run test over a clean database", :blue)
                io.puts Termline::Style.colorize("-> You can use: rake dev:db:reset", :blue)
                io.puts
                io.puts
            end

            def record(test)
                super

                # Only print the line if the configuration allows it
                return if ENV["QUIET"]

                # Map result codes to styles
                status_map = {
                    "." => [:green, "PASS"],
                    "S" => [:yellow, "SKIP"],
                    "W" => [:yellow, "WARN"],
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

                io.puts(parts.join(" "))
            end

            def report
                run_statistics_reporter(:report)

                total_tests = count.to_i
                total_failures = failures.to_i
                total_errors = errors.to_i
                total_warnings = warnings.to_i
                total_skips = skips.to_i
                total_assertions = assertions.to_i
                duration = total_time.to_f

                passed = total_tests - total_failures - total_errors - total_warnings - total_skips
                success_rate = total_tests.zero? ? 0 : ((passed.to_f / total_tests) * 100).round(1)
                empty_filtered_run = total_tests.zero? && options[:include]
                status = if empty_filtered_run || total_failures.positive? || total_errors.positive? || total_warnings.positive?
                    "FAIL"
                else
                    "PASS"
                end

                io.puts
                io.puts

                status_color = status == "FAIL" ? :red : :blue
                failures_color = total_failures.positive? ? :red : :blue
                errors_color = total_errors.positive? ? :red : :blue
                warnings_color = total_warnings.positive? ? :yellow : :blue
                success_rate_color = status == "FAIL" ? :red : :blue

                write_summary_row(status,                    tag: "STATUS . . . . . . . :", color: status_color)
                write_summary_row(total_tests,               tag: "TESTS. . . . . . . . :")
                write_summary_row(passed,                    tag: "PASSED . . . . . . . :")
                write_summary_row(total_failures,            tag: "FAILURES . . . . . . :", color: failures_color)
                write_summary_row(total_errors,              tag: "ERRORS . . . . . . . :", color: errors_color)
                write_summary_row(total_warnings,            tag: "WARNINGS . . . . . . :", color: warnings_color)
                write_summary_row(total_skips,               tag: "SKIPPED. . . . . . . :")
                write_summary_row(total_assertions,          tag: "ASSERTIONS . . . . . :")
                write_summary_row("#{success_rate}%",        tag: "SUCCESS RATE . . . . :", color: success_rate_color)
                write_summary_row(format("%.2fs", duration), tag: "TIME . . . . . . . . :")

                io.puts
                io.puts

                if empty_filtered_run
                    write_status_message(
                        "No tests matched filter: #{options[:include]}",
                        tag: "FAILURE",
                        color: :red,
                        icon: :error
                    )
                elsif status == "PASS"
                    write_status_message("Test suite passed", tag: "SUCCESS:", color: :green, icon: :success)
                else
                    write_status_message("Test suite failed", tag: "FAILURE", color: :red, icon: :error)
                end

                io.puts
                io.puts

                print_result_details if total_failures.positive? || total_errors.positive? || total_warnings.positive? || total_skips.positive?

            end

            private

            # Skip SummaryReporter's default terminal output while reusing the
            # statistics lifecycle implemented by its parent class.
            def run_statistics_reporter(method_name)
                Minitest::StatisticsReporter
                    .instance_method(method_name)
                    .bind(self)
                    .call
            end

            def write_summary_row(value, tag:, color: :blue)
                io.puts Termline::Msg.builder(value, tag: tag, color: color, time: false)
            end

            def write_status_message(message, tag:, color:, icon:)
                io.puts Termline::Msg.builder(message, tag: tag, icon: icon, color: color, time: true)
            end

            def print_result_details
                failed_results = Array(results).select(&:failure)

                return if failed_results.empty?

                failed_results.each_with_index do |result, index|
                    failure = result.failure
                    failure_tag, color, icon = result_style(failure)
                    failure_msg = "#{result.klass}##{result.name} (#{result.assertions} asserts)"

                    io.puts
                    io.puts Termline::Space.builder("-·-     ", 6)
                    io.puts

                    io.puts Termline::Msg.builder(
                        failure_msg,
                        tag: " #{Termline::Style.icon(icon)} #{failure_tag} #{index + 1}:",
                        color: color,
                        time: false
                    )
                    io.puts Termline::Msg.builder(
                        format_failure_location(failure),
                        tag: " #{Termline::Style.icon(:debug)}  Location:",
                        color: :yellow,
                        time: false
                    )

                    print_result_message(failure)
                end

                io.puts
            end

            def result_style(failure)
                case failure
                when Minitest::Skip
                    ["SKIP", :yellow, :warning]
                when Minitest::UnexpectedWarning
                    ["WARNING", :yellow, :warning]
                when Minitest::UnexpectedError
                    ["ERROR", :red, :error]
                else
                    ["FAILURE", :red, :error]
                end
            end

            def format_failure_location(failure)
                location = failure.location.to_s
                return "Location unknown" if location.empty? || location == "unknown:-1"

                match = location.match(/\A(.+):(\d+)\z/)
                return location unless match

                "#{match[1]} (line: #{match[2]})"
            end

            def print_result_message(failure)
                if failure.is_a?(Minitest::Skip)
                    io.puts Termline::Style.colorize(
                        " #{Termline::Style.icon(:warning)}  Reason: #{failure.message}",
                        :yellow
                    )
                elsif failure.is_a?(Minitest::UnexpectedWarning)
                    io.puts Termline::Style.colorize(
                        " #{Termline::Style.icon(:warning)}  #{failure.message}",
                        :yellow
                    )
                else
                    failure.message.to_s.lines.each do |message|
                        io.puts parse_minitest_assertion_messages(message)
                    end
                end
            end

            def parse_minitest_assertion_messages(message)
                message.to_s.rstrip.lines.map do |line|
                    msg = line.strip

                    case msg

                        # 1. Unified Diff Headers
                        # Covers Minitest diff output like:
                        # --- expected
                        # +++ actual
                        # @@ -1 +1 @@
                        when /^--- /
                            Termline::Style.colorize(msg, :red)

                        when /^\+\+\+ /
                            Termline::Style.colorize(msg, :green)

                        when /^@@ / 
                            Termline::Style.colorize("#{msg}", :skyblue)

                        # 2. Unified Diff Content Lines
                        # Covers actual changed lines inside the diff, like:
                        # -[:lesli_support_item_tasks, "lesli_support"]
                        # +[:lesli_support_items_tasks, "lesli_support"]
                        # The negative lookahead avoids matching the diff headers above.
                        when /^-(?!-)/
                            Termline::Style.colorize(" #{Termline::Style.icon(:remove)} #{msg}", :red)

                        when /^\+(?!\+)/
                            Termline::Style.colorize(" #{Termline::Style.icon(:add)} #{msg}", :green)

                        # 3. Boolean/Nil Failures
                        # Covers cases like:
                        # Expected true to be nil
                        # Expected false to be truthy
                        # Expected "abc" to be empty
                        when /Expected (.*) to be (nil|truthy|falsey)/, /Expected (.*) to be (.*)/
                            Termline::Style.colorize(" #{Termline::Style.icon(:info)}  #{msg}", :skyblue)

                        # 4. Standard Expected vs Actual Output
                        # Covers simple assertion output like:
                        # Expected: 1
                        # Actual: 2
                        when /^Expected:\s+/
                            Termline::Style.colorize(" #{Termline::Style.icon(:add)}  #{msg}", :green)

                        when /^Actual:\s+/
                            Termline::Style.colorize(" #{Termline::Style.icon(:remove)}    #{msg}", :red)

                        # 5. Rails Difference Failures
                        # Covers assertions like:
                        # "User.count" didn't change by 1
                        # actual change was 0
                        when /"(.*)" didn't change by (.*)/, /actual change was (.*)/
                            Termline::Style.colorize(" #{Termline::Style.icon(:warning)}  #{msg}", :yellow)

                        # 6. Collection/Count Failures
                        # Covers collection assertions like:
                        # Expected 5 elements, found 2
                        # Expected exactly 1 nodes
                        when /Expected (.*) elements?, found (.*)/, /Expected exactly (.*) nodes/
                            Termline::Style.colorize(" #{Termline::Style.icon(:info)}  #{msg}", :blue)

                        # 7. Fallback for Custom or Unrecognized Messages
                        # Covers anything else not matched above.
                        else 
                            Termline::Style.colorize(" #{Termline::Style.icon(:debug)}   #{msg}", :gray)
                    end
                end.join("\n")
            end
        end
    end
end
