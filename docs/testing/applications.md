# Testing Rails applications

Use the application profile for a full Rails application or for a Lesli workspace that loads several engines and gems into one test process.

## Test helper

A conventional `test/test_helper.rb` is:

```ruby
ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require "lesli_testing"

LesliTesting.app(
  "LesliBuilder",
  coverage_min_coverage: 90
)

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end
```

Loading `rails/test_help` first makes the LesliTesting Rails base classes available. Keep the configuration before any explicit `require` calls that load application components solely for the test suite.

## Application coverage profile

The application profile starts with SimpleCov's Rails defaults and tracks Ruby files under:

```text
app/
lib/
engines/
gems/
```

This profile is useful in a monorepo because source files from locally installed engines and gems can be included in the same report.

## Example model test

Use the standard Rails base class or the LesliTesting model base class:

```ruby
require "test_helper"

class AccountTest < LesliTesting::ModelTester
  test "is inactive after its expiration time" do
    account = accounts(:expired)

    travel_to account.expires_at + 1.minute do
      refute account.active?
    end
  end
end
```

`LesliTesting::ModelTester` includes `ActiveSupport::Testing::TimeHelpers`.

## Example integration test

```ruby
require "test_helper"

class AccountsControllerTest < LesliTesting::IntegrationTester
  test "returns the accounts collection" do
    get accounts_url, as: :json

    expect_response_with_successful
    assert_kind_of Array, response_json
  end
end
```

See [Testing tools](/gems/testing/about/tools) for the response helpers and fixture behavior.

## Run application tests

```shell
bin/rails test
bin/rails test test/models/account_test.rb
COVERAGE=true bin/rails test
QUIET=true COVERAGE=true bin/rails test
```

Coverage output is written under `coverage/` in the directory where the test process runs.
