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

Coverage is disabled during ordinary test runs. Set `COVERAGE` to `true`, `1`, or `yes` to start SimpleCov:

```shell
COVERAGE=true bundle exec rake
```

When coverage is enabled, requiring `lesli_testing` starts Ruby's line coverage before the LesliTesting implementation, Rails, or the project under test is loaded. The subsequent `LesliTesting.app`, `LesliTesting.engine`, or `LesliTesting.gem` call applies the selected SimpleCov profile, formatters, and minimum threshold.

Every coverage run produces:

| Format | Output |
| --- | --- |
| Console | Summary in the test command output |
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
| `COVERAGE` | Enables SimpleCov with the console and Cobertura formatters when set to `true`, `1`, or `yes`. |
| `QUIET` | Hides individual test-result lines from the custom reporter when set to `true`, `1`, or `yes`. |

Values are case-insensitive and surrounding whitespace is ignored. Only `true`, `1`, and `yes` enable these options. Unset variables and values such as `false`, `0`, and `no` leave them disabled.

## Shared Rails test classes

The shared classes are registered through ActiveSupport load hooks. They are created when `rails/test_help` loads their corresponding Rails classes, regardless of whether LesliTesting was configured before or after the Rails application booted. Engine suites should still run through `bundle exec rails test` or `bundle exec rake app:test`.

### IntegrationTester

`LesliTesting::IntegrationTester` inherits from `ActionDispatch::IntegrationTest` and includes response helpers:

```ruby
class AccountsControllerTest < LesliTesting::IntegrationTester
  test "returns JSON" do
    get accounts_url, as: :json

    assert_successful_json_response
    assert_kind_of Array, response_json
  end
end
```

Available helpers:

| Helper | Behavior |
| --- | --- |
| `response_json(response = self.response)` | Parses the public response body with `JSON.parse`; a blank body becomes an empty hash. An explicit response may be supplied. |
| `assert_successful_json_response(response = self.response)` | Asserts a successful response and the `application/json` media type, independently of its charset. |
| `expect_response_with_successful(response = self.response)` | Compatibility wrapper for `assert_successful_json_response`. |

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

## Engine fixtures and migrations

For the engine profile, LesliTesting waits for Rails to load and then resolves the owner from the name passed to `LesliTesting.engine`. With a conventional engine layout it automatically registers:

- the owner's `test/fixtures` and `test/fixtures/files` directories;
- shared fixtures from `Lesli`;
- the dummy application's, owner engine's, and shared Lesli migration directories;
- all fixtures on `ActiveSupport::TestCase` and their paths on integration tests.

The migration Railtie runs only when `Rails.env.test?`. The engine name is the default target; use `engine:` when the reporter name and engine constant differ:

```ruby
LesliTesting.engine("My engine tests", engine: "MyEngine")
```

`Lesli` is always the shared base for Rails application and engine profiles. Additional values passed through `shared:` are appended without removing it. LesliTesting maps these fixture sets to their namespaced models:

| Fixture set | Model |
| --- | --- |
| `lesli_users` | `Lesli::User` |
| `lesli_accounts` | `Lesli::Account` |

Fixture paths and classes are applied through Rails load hooks. Migration paths are added during the dummy application's test boot and again when Active Record becomes available; both operations preserve and de-duplicate existing paths. This allows coverage to start before Rails without losing test data configuration.

Custom owners, paths, shared engines, fixture sets, model mappings, and migration paths can be supplied through the `fixtures:` and `migrations:` options. See [Testing Rails engines](/gems/testing/testing/engines) for the complete configuration.
