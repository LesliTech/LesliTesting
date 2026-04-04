# test/demo_test.rb
require "test_helper"

class DemoTest < Minitest::Test

    def test_expected_nil_with_true
        assert_nil true
    end

    def test_expected_nil_with_string
        assert_nil "string"
    end

    def test_expected_truthy_with_false
        assert false
    end

    def test_expected_truthy_with_nil
        assert nil
    end

    def test_expected_equal
        assert_equal 1, 2
    end

    def test_unified_diff
        assert_equal(
            [:lesli_support_item_tasks, "lesli_support"],
            [:lesli_support_items_tasks, "lesli_support"]
        )
    end

    def test_difference_failure
        assert_difference("User.count", 1) do
            # intentionally no-op
        end
    end

    def test_collection_failure
        assert_equal 5, [1, 2].size
    end

    def test_custom_fallback
        flunk "Something unexpected happened in custom reporter demo"
    end
end
