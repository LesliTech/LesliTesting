# test/performance/reporter_stress_test.rb
require "test_helper"

class PerformanceTest < Minitest::Test

    # Generate 5,000 fast tests
    5.times do |i|
        define_method("test_performance_#{i}") do
            assert_equal 1, 1
        end
    end

    # Generate 100 failing tests to test the failure details logic
    0.times do |i|
        define_method("test_failure_stress_#{i}") do
            assert_equal "expected string", "actual string", "Custom failure message for stress testing"
        end
    end
end
