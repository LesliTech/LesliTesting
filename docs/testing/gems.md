# Testing Ruby gems

LesliTesting supports standalone Ruby gems without Rails. In this mode it configures Minitest, the custom terminal reporter, SimpleCov, and all coverage formatters. Rails-only base classes and fixture integration are skipped.

## Recommended structure

```text
my_gem/
├── lib/
│   ├── my_gem.rb
│   └── my_gem/
│       └── version.rb
├── test/
│   ├── test_helper.rb
│   └── my_gem_test.rb
├── Gemfile
├── my_gem.gemspec
└── Rakefile
```

## Test helper

Configure LesliTesting before requiring the library under test. This load order allows SimpleCov to observe every library file loaded by the test process:

```ruby
# test/test_helper.rb
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lesli_testing"

LesliTesting.gem(
  "MyGem",
  coverage_min_coverage: 90
)

require "minitest/autorun"
require "my_gem"
```

## Test files

Write standard Minitest tests and require the shared helper:

```ruby
# test/my_gem_test.rb
require "test_helper"

class MyGemTest < Minitest::Test
  def test_returns_its_version
    refute_empty MyGem::VERSION
  end
end
```

Nested test directories work normally:

```text
test/
├── integration/
├── unit/
├── support/
└── test_helper.rb
```

Require support files explicitly from `test_helper.rb`, or configure the project's test task to include them.

## Rake task

```ruby
# Rakefile
require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

task default: :test
```

The default Minitest task finds files matching the conventional test pattern.

## Run gem tests

```shell
bundle exec rake
bundle exec ruby -Itest test/my_gem_test.rb
COVERAGE=true bundle exec rake
QUIET=true COVERAGE=true bundle exec rake
```

## Coverage behavior

The gem profile uses the standard SimpleCov Rails base profile. For a conventional standalone gem, this tracks Ruby source under `lib/`, filters test files, and places generated reports in `coverage/`.

If the coverage result unexpectedly omits a file, verify that LesliTesting is configured before `require "my_gem"` and before any other dependency loads the gem indirectly.
