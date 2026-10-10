# Testing Rails engines

Use the engine profile for a mountable or isolated Rails engine. Engine tests run through a dummy Rails application, which acts as the host application and provides the complete Rails boot process used by routes, controllers, models, migrations, Devise, Zeitwerk, and integration tests.

## Keep a complete dummy application

Generate the engine and its dummy application with the Rails plugin generator. Do not reduce the dummy app to only `config/` and `db/`: files that look unused locally may be required when CI enables eager loading or when a dependency such as Devise resolves host-application constants.

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
│   │   ├── app/
│   │   │   ├── controllers/
│   │   │   │   └── application_controller.rb
│   │   │   └── models/
│   │   │       └── application_record.rb
│   │   ├── config/
│   │   │   ├── application.rb
│   │   │   ├── environment.rb
│   │   │   ├── environments/
│   │   │   │   └── test.rb
│   │   │   └── routes.rb
│   │   ├── db/
│   │   └── Rakefile
│   ├── fixtures/
│   │   └── files/
│   ├── integration/
│   ├── models/
│   └── test_helper.rb
├── my_engine.gemspec
└── Rakefile
```

At minimum, preserve the host application's standard base classes:

```ruby
# test/dummy/app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
end
```

```ruby
# test/dummy/app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
```

These top-level classes belong to the dummy host. They are separate from namespaced engine classes such as `MyEngine::ApplicationController` and `MyEngine::ApplicationRecord`.

If an old engine has an incomplete dummy app, regenerate the same engine type with the same Rails version in a temporary directory and copy the missing dummy files and configuration deliberately. Review the diff instead of replacing application code blindly.

## Declare dependencies explicitly

An engine must declare every runtime dependency it uses. LesliTesting supplies testing infrastructure; it is not a substitute for declaring Lesli itself:

```ruby
# my_engine.gemspec
spec.add_dependency "lesli", "~> 5.1"
```

For a repository that maintains test dependencies in its Gemfile, keep the direct declaration there as well:

```ruby
gemspec

gem "lesli"
gem "lesli_testing"
```

GitHub Actions installs only dependencies available from the declared sources. A neighboring checkout, locally installed development build, or unreleased fix is not available to CI. Use `bundle info lesli` to verify the exact source, and publish or reference a version containing the required fix before updating the engine lockfile.

## Test helper

Configure LesliTesting before booting the dummy application so SimpleCov can observe engine boot code. Run the suite through Rails' test runner, which loads the Rails testing framework required by the shared tester classes.

```ruby
ENV["RAILS_ENV"] ||= "test"

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

The LesliTesting Rails engine adds the Lesli migration directory without duplicating an existing path. The test helper still owns the dummy application's and current engine's migration paths.

Tests may use the shared base classes with this load order:

```ruby
class AccountTest < LesliTesting::ModelTester
end

class AccountsControllerTest < LesliTesting::IntegrationTester
end

class NavigationHelperTest < LesliTesting::ViewTester
end
```

## Rakefile

Use Rails' engine task so commands execute against the dummy application:

```ruby
require "bundler/setup"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)

load "rails/tasks/engine.rake"

require "bundler/gem_tasks"
```

## Match CI locally

The generated test environment normally contains:

```ruby
config.eager_load = ENV["CI"].present?
```

An ordinary local run may therefore pass while CI fails on a missing or incorrectly named constant. Run both the fast local suite and an eager-loaded CI-equivalent suite before pushing:

```shell
bundle exec rake app:test
CI=true bundle exec rails test
```

Enable coverage independently when needed:

```shell
COVERAGE=true bundle exec rake app:test
CI=true COVERAGE=true bundle exec rails test
```

Do not fix an eager-loading failure by setting `config.eager_load = false` in CI. The failure usually identifies an invalid constant name, a missing standard Rails base class, an incomplete dummy app, or an undeclared dependency.

## Common CI-only failures

| Error | Typical cause | Correct fix |
| --- | --- | --- |
| `uninitialized constant MyEngine::...::ApplicationRecord` | A namespaced model expects the engine's conventional base record, but its file was removed or misnamed. | Restore `MyEngine::ApplicationRecord` in the path Zeitwerk expects. Keep framework-specific base records separate when they have different responsibilities. |
| `uninitialized constant ApplicationController` while loading Devise | The dummy host does not define the standard top-level controller. | Restore `test/dummy/app/controllers/application_controller.rb`. |
| A published dependency fails but a workspace run passes | Local Bundler resolution differs from CI, or the fix has not been released. | Compare `bundle info`, publish/reference the fixed version, and update `Gemfile.lock`. |
| Duplicate or invalid migration paths | The same dependency path is registered more than once, or a Rails paths object is treated like an Array. | Let LesliTesting de-duplicate Lesli's migration path and configure only the dummy/current engine paths explicitly. |
| `LesliTesting::ViewTester` or another shared tester is missing | The test file was executed directly with Ruby before Rails loaded its testing framework. | Run engine tests with `bundle exec rails test` or `bundle exec rake app:test`. |

When diagnosing a CI-only boot failure, reproduce it locally with `CI=true`, read the first application or gem file in the stack trace, and fix that constant before chasing later framework frames.

## Engine coverage profile

The engine profile loads SimpleCov's Rails defaults and excludes files under `test/`. It produces console, HTML, and Cobertura reports when `COVERAGE` is present.

When the engine is developed inside a host application, run commands from the engine directory so its own Gemfile, test helper, lockfile, and coverage directory are used.
