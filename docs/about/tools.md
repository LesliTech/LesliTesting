# Testing tools

LesliTesting configures a set of tools around standard Minitest. The project still owns its test cases, assertions, fixtures, and Rails test environment.

## Minitest reporter

The custom reporter replaces the default Minitest reporter and prints:

- A status line for each test unless quiet mode is enabled
- `PASS`, `SKIP`, `FAIL`, or `ERROR` labels
- Test class and method names
- Assertion counts
- Execution time for tests taking more than one second
- Totals for tests, passes, failures, errors, skips, assertions, success rate, and duration
- Formatted locations and assertion details for failures

Assertion counts are color-coded to make tests with very few assertions easy to spot. This is guidance in the terminal output; it does not change whether a test passes.

Set `QUIET=true` to suppress per-test lines while keeping the final summary and failure information:

```shell
QUIET=true bundle exec rake
```

## Coverage

Coverage is disabled during ordinary test runs. Set `COVERAGE` to any value to start SimpleCov:

```shell
COVERAGE=true bundle exec rake
```

Every coverage run produces:

| Format | Output |
| --- | --- |
| Console | Summary in the test command output |
| HTML | `coverage/index.html` |
| Cobertura | `coverage/coverage.xml` |

The minimum line-coverage threshold defaults to 90 percent. Configure it for a suite with `coverage_min_coverage`:

```ruby
LesliTesting.gem(
  "MyGem",
  coverage_min_coverage: 85
)
```

The coverage process exits unsuccessfully when the result is below the configured threshold.

Use `coverage_missing_len` to limit the length of missing-line details in the console formatter:

```ruby
LesliTesting.engine(
  "MyEngine",
  coverage_missing_len: 40
)
```

Set it to `0` to remove the limit.

## Environment variables

| Variable | Behavior |
| --- | --- |
| `COVERAGE` | Enables SimpleCov and all three coverage formatters. |
| `QUIET` | Hides individual test-result lines from the custom reporter. |

`COVERAGE` and `QUIET` are enabled by presence. Do not set them to `false`; leave them unset when the behavior should be disabled.

## Shared Rails test classes

The shared classes are defined only when their corresponding Rails classes have already been loaded.

### IntegrationTester

`LesliTesting::IntegrationTester` inherits from `ActionDispatch::IntegrationTest` and includes response helpers:

```ruby
class AccountsControllerTest < LesliTesting::IntegrationTester
  test "returns JSON" do
    get accounts_url, as: :json

    expect_response_with_successful
    assert_kind_of Array, response_json
  end
end
```

Available helpers:

| Helper | Behavior |
| --- | --- |
| `response_json` | Parses the response body with `JSON.parse`; a blank body becomes an empty hash. |
| `expect_response_with_successful` | Asserts a successful response and the `application/json; charset=utf-8` content type. |

### ModelTester

`LesliTesting::ModelTester` inherits from `ActiveSupport::TestCase` and includes `ActiveSupport::Testing::TimeHelpers`:

```ruby
class SubscriptionTest < LesliTesting::ModelTester
  test "expires tomorrow" do
    travel_to Time.zone.local(2026, 9, 26, 12) do
      assert_equal Date.new(2026, 9, 27), Subscription.expires_tomorrow
    end
  end
end
```

### ViewTester

`LesliTesting::ViewTester` inherits from `ActionView::TestCase`. When available, subclasses receive `Lesli::HtmlHelper` and `Lesli::SystemHelper`:

```ruby
class NavigationHelperTest < LesliTesting::ViewTester
  test "renders navigation" do
    assert_includes render_navigation, "Dashboard"
  end
end
```

## Lesli fixtures

When `Lesli` is loaded, LesliTesting registers the Lesli engine's fixture directory and file-fixture directory with `ActiveSupport::TestCase`. It also maps these fixture sets to their namespaced models:

| Fixture set | Model |
| --- | --- |
| `lesli_users` | `Lesli::User` |
| `lesli_accounts` | `Lesli::Account` |

The fixture integration runs during configuration. Load the Rails environment and the Lesli engine before calling the profile method when the suite depends on these shared fixtures.

Engine-specific fixture paths remain the responsibility of the engine test helper. See [Testing Rails engines](/gems/testing/testing/engines) for an example.
