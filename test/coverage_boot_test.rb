# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"
require_relative "test_helper"

class CoverageBootTest < Minitest::Test
    PROJECT_ROOT = File.expand_path("..", __dir__)
    LIB_PATH = File.join(PROJECT_ROOT, "lib")
    CORE_PATH = File.join(LIB_PATH, "lesli_testing", "core.rb")

    def test_coverage_starts_before_lesli_testing_implementation_loads
        Dir.mktmpdir("lesli-testing-coverage") do |coverage_dir|
            script = <<~RUBY
                require "lesli_testing"

                LesliTesting.gem("CoverageBoot", coverage_min_coverage: 0)
                SimpleCov.coverage_dir(ARGV.fetch(0))

                lines = Coverage.peek_result.fetch(ARGV.fetch(1)).fetch(:lines)
                abort "LesliTesting core has no measured lines" unless lines.compact.any?(&:positive?)
            RUBY

            stdout, stderr, status = Open3.capture3(
                { "COVERAGE" => "true" },
                RbConfig.ruby,
                "-I#{LIB_PATH}",
                "-e",
                script,
                coverage_dir,
                CORE_PATH,
                chdir: PROJECT_ROOT
            )

            assert status.success?, [stdout, stderr].join("\n")
            assert File.file?(File.join(coverage_dir, "coverage.xml")),
                "Expected Cobertura report at #{coverage_dir}/coverage.xml"
        end
    end
end
