# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "benchmark"
require "stringio"
require "minitest"
require "termline"
require "lesli_testing/minitest/cli_reporter"

iterations = Integer(ENV.fetch("ITERATIONS", "5000"), 10)
abort "ITERATIONS must be greater than zero" unless iterations.positive?

output = StringIO.new
reporter = LesliTesting::Reporters::CliReporter.new(
    output,
    lesli_testing_profile: "gem",
    lesli_testing_project_name: "ReporterBenchmark"
)

elapsed = Benchmark.realtime do
    reporter.start

    iterations.times do |index|
        result = Minitest::Result.new("test_benchmark_#{index}")
        result.klass = "ReporterBenchmark"
        result.assertions = 1
        result.time = 0.0001
        reporter.record(result)
    end

    reporter.report
end

rate = iterations / elapsed

Termline.success(
    "Reporter benchmark completed",
    iterations: iterations,
    elapsed: format("%.3fs", elapsed),
    rate: format("%.0f results/second", rate)
)
