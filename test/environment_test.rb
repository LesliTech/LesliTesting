# frozen_string_literal: true

require_relative "test_helper"

class EnvironmentTest < Minitest::Test
    def test_true_values_enable_the_option
        ["true", "TRUE", " true ", "1", "yes", "YES"].each do |value|
            assert LesliTesting::Environment.enabled?("OPTION", env: { "OPTION" => value }), value
        end
    end

    def test_other_values_disable_the_option
        [nil, "", "false", "FALSE", "0", "no", "off", "anything"].each do |value|
            refute LesliTesting::Environment.enabled?("OPTION", env: { "OPTION" => value }), value.inspect
        end
    end
end
