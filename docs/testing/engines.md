# Testing Rails engines

Use the engine profile for a mountable or isolated Rails engine. An engine test suite normally boots a small dummy Rails application so that routes, controllers, models, migrations, and integration tests run in a real Rails environment.

## Recommended structure

```text
my_engine/
├── app/
├── config/
├── db/
│   └── migrate/
├── lib/
│   ├── my_engine.rb
│   └── my_engine/
│       └── engine.rb
├── test/
│   ├── dummy/
│   │   ├── config/
│   │   └── db/
│   ├── fixtures/
│   │   └── files/
│   ├── integration/
│   ├── models/
│   ├── test_helper.rb
│   └── my_engine_test.rb
├── my_engine.gemspec
└── Rakefile
```

## Test helper with early coverage

Configure LesliTesting before booting the dummy application when complete engine boot coverage is the priority:

```ruby
ENV["RAILS_ENV"] = "test"

require "lesli_testing"

LesliTesting.engine(
  "MyEngine",
  coverage_min_coverage: 90
)

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Migrator.migrations_paths = [
  File.expand_path("dummy/db/migrate", __dir__),
  File.expand_path("../db/migrate", __dir__)
]

if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  fixture_path = File.expand_path("fixtures", __dir__)

  ActiveSupport::TestCase.fixture_paths = [fixture_path]
  ActionDispatch::IntegrationTest.fixture_paths = [fixture_path]
  ActiveSupport::TestCase.file_fixture_path = File.join(fixture_path, "files")
  ActiveSupport::TestCase.fixtures :all
end
```

This ordering starts SimpleCov before the dummy application loads the engine. Because the Rails test classes do not yet exist at configuration time, use standard Rails base classes in this arrangement:

```ruby
class DashboardTest < ActionDispatch::IntegrationTest
end
```

## Test helper with shared LesliTesting classes

If the engine uses `LesliTesting::IntegrationTester`, `LesliTesting::ModelTester`, or `LesliTesting::ViewTester`, load Rails first:

```ruby
ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "lesli_testing"

LesliTesting.engine("MyEngine")
```

This makes the shared classes available, but code eagerly loaded while the dummy application boots starts before coverage. Rails-autoloaded engine code is still measured when tests first reference it.

## Engine coverage profile

The engine profile loads SimpleCov's Rails defaults and excludes files under `test/`. It produces console, HTML, and Cobertura reports when `COVERAGE` is present.

## Rake task

Add a Minitest task to the engine's `Rakefile`:

```ruby
require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

task default: :test
```

## Run engine tests

From the engine directory:

```shell
bundle exec rake
bundle exec ruby -Itest test/models/account_test.rb
COVERAGE=true bundle exec rake
QUIET=true COVERAGE=true bundle exec rake
```

When the engine is developed inside a host application, run commands from the engine directory if its own `Gemfile`, test helper, and coverage directory should be used.
