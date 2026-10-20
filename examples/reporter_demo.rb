# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lesli_testing"

LesliTesting.gem("ReporterDemo")

require "minitest/autorun"

# Run this file manually to inspect the reporter's pass, skip, failure, diff,
# and error output. Intentional failures make the process exit unsuccessfully.
class ReporterDemo < Minitest::Test
    def test_pass
        assert_equal 2, 1 + 1
    end

    def test_skip
        skip "Manual reporter skip example"
    end

    def test_expected_and_actual
        assert_equal 1, 2
    end

    def test_boolean_failure
        assert_nil true
    end

    def test_unified_diff
        assert_equal(
            [:lesli_support_item_tasks, "lesli_support"],
            [:lesli_support_items_tasks, "lesli_support"]
        )
    end

    def test_collection_failure
        assert_equal 5, [1, 2].size
    end

    def test_error
        raise "Manual reporter error example"
    end
end
