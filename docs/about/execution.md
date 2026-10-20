# Load order and process behavior

LesliTesting separates coverage, Minitest, and Rails initialization so the same
public API works for Rails applications, Rails engines, and standalone Ruby
gems.

## Definitive initialization order

### 1. Require LesliTesting

```ruby
require "lesli_testing"
```

The entrypoint reads `COVERAGE`. When enabled, it starts Ruby line coverage
before Ruby compiles the rest of LesliTesting, Rails, or the project under test.
It then loads the small public API from `lesli_testing/core`.

Requiring the gem alone does not load Rails integrations and does not start
SimpleCov when coverage is disabled.

### 2. Select exactly one profile

```ruby
LesliTesting.app("LesliBuilder")
# or LesliTesting.engine("LesliShield")
# or LesliTesting.gem("Termline")
```

The profile call:

1. Stores the project name and options.
2. Attaches SimpleCov to the already running native coverage session when
   `COVERAGE` is enabled.
3. Registers the LesliTesting Minitest plugin.
4. For `app` and `engine`, registers deferred Rails fixtures and tester hooks.
5. For `engine`, registers the test-only migration Railtie for the selected
   engine target.

SimpleCov starts only once in a process. Call one profile method per test
process; changing profiles after source files have loaded cannot recover missed
coverage.

### 3. Load the project runtime

Rails application:

```ruby
require_relative "../config/environment"
require "rails/test_help"
```

Rails engine:

```ruby
require_relative "dummy/config/environment"
require "rails/test_help"
```

Ruby gem:

```ruby
require "minitest/autorun"
require "my_gem"
```

For Rails profiles, ActiveSupport hooks create
`LesliTesting::IntegrationTester`, `LesliTesting::ModelTester`, and
`LesliTesting::ViewTester` only when their Rails base classes become available.
Fixture paths are installed through the same hooks. Engine migration paths are
registered only when `Rails.env.test?`.

This deferred phase is why an engine test that inherits from a shared tester
must run through the Rails test runner instead of being executed directly with
plain Ruby.

### 4. Start Minitest

When Minitest initializes its plugins, LesliTesting removes other registered
reporters and installs `LesliTesting::Reporters::CliReporter`. This guarantees a
single, consistent output format in local runs and CI.

The reporter records pass, failure, error, warning, and skip results. `QUIET`
may hide individual result lines, but the summary and failure details remain.

### 5. Finalize the process

Minitest computes the suite result. When coverage is enabled, SimpleCov then
writes the console report and `coverage/coverage.xml`, and validates the minimum
coverage threshold.

Coverage starts at require time but is formatted at process exit. Do not force
an early process exit with `exit!`, because Ruby at-exit handlers will not run.

## Correct complete examples

### Rails application

```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"

require "lesli_testing"
LesliTesting.app("LesliBuilder", coverage_min_coverage: 90)

require_relative "../config/environment"
require "rails/test_help"
```

### Rails engine

```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"

require "lesli_testing"
LesliTesting.engine("LesliShield", coverage_min_coverage: 90)

require_relative "dummy/config/environment"
require "rails/test_help"
```

If the display name and engine constant differ, configure the target explicitly:

```ruby
LesliTesting.engine("Shield tests", engine: "LesliShield")
```

### Standalone Ruby gem

```ruby
# test/test_helper.rb
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lesli_testing"
LesliTesting.gem("Termline", coverage_min_coverage: 90)

require "minitest/autorun"
require "termline"
```

## Environment variables

| Variable | Default | Enabled values | Effect |
| --- | --- | --- | --- |
| `COVERAGE` | Disabled | `true`, `1`, `yes` | Starts native line coverage and SimpleCov. |
| `QUIET` | Disabled | `true`, `1`, `yes` | Suppresses per-test reporter lines. |

Parsing is case-insensitive and ignores surrounding whitespace. Examples such
as `TRUE`, ` Yes `, and `1` enable the option. Unset variables and values such
as `false`, `0`, `no`, and an empty string leave it disabled.

`COVERAGE` must be present before the Ruby process requires `lesli_testing`.
Changing it later is too late to measure already loaded files. `QUIET` is read
while the reporter records tests and therefore affects output only.

## Exit codes

| Code | Produced when |
| ---: | --- |
| `0` | All executed tests pass. A suite containing skips may still return `0`. |
| `1` | A failure, unexpected exception, `-Werror` warning, or filtered run with no matching tests occurs. |
| `2` | SimpleCov line coverage is below `coverage_min_coverage` after an otherwise successful run. |

A filter with no matches is intentionally a failure:

```shell
bundle exec rake test TESTOPTS="--name /NOT_FOUND/"
```

It prints the missing filter and returns `1`, preventing an empty CI run from
appearing successful.

These are the LesliTesting/Minitest/SimpleCov results. Bundler failures, syntax
errors before Minitest starts, signals, and operating-system errors may return
other non-zero codes.

## CI commands

The standard commands used by LesliActions are:

```shell
COVERAGE=true bundle exec rake test
test -f coverage/coverage.xml
bundle exec rake build
```

Together they verify the suite, the coverage threshold and Cobertura report,
and the distributable gem package.
