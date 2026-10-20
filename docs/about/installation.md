# Installation and configuration

## Install the gem

Add LesliTesting to the test group of a Rails application, Rails engine, or Ruby gem:

```shell
bundle add lesli_testing --group test
```

The equivalent `Gemfile` entry is:

```ruby
group :test do
  gem "lesli_testing"
end
```

When the dependency is declared in a gemspec, keep it as a development dependency because applications using the released gem do not need LesliTesting at runtime:

```ruby
spec.add_development_dependency "lesli_testing"
```

For local development inside a Lesli workspace, point Bundler to the checkout:

```ruby
group :test do
  gem "lesli_testing", path: "gems/LesliTesting"
end
```

Then install the dependencies:

```shell
bundle install
```

## Select a project profile

Require LesliTesting in `test/test_helper.rb` and call one configuration method:

```ruby
require "lesli_testing"

LesliTesting.app("LesliBuilder")
```

Available methods are:

| Method | Intended project | Coverage profile |
| --- | --- | --- |
| `LesliTesting.app(name, options = {})` | Rails application | Tracks Ruby files in `app`, `lib`, `engines`, and `gems`. |
| `LesliTesting.engine(name, options = {})` | Rails engine | Uses the Rails profile and filters test files. |
| `LesliTesting.gem(name, options = {})` | Standalone Ruby gem | Tracks the standard `app` and `lib` paths and filters test files. |

Do not call more than one profile method in the same test process. All three methods configure the same global Minitest and SimpleCov instances.

## Configuration options

Pass options as keyword-style hash entries:

```ruby
LesliTesting.engine(
  "LesliShield",
  coverage_missing_len: 30,
  coverage_min_coverage: 80
)
```

| Option | Type | Default | Description |
| --- | --- | ---: | --- |
| `coverage_missing_len` | Integer | `25` | Maximum number of characters displayed for missing lines in console coverage output. Use `0` for no limit. |
| `coverage_min_coverage` | Numeric | `90` | Minimum required line-coverage percentage. A coverage run fails below this value. |

The selected project profile is set internally. Applications should not pass `coverage_profile` directly.

## Load order

Coverage must start before the files being measured are required. Put the LesliTesting configuration as early as the test environment permits:

```ruby
require "lesli_testing"
LesliTesting.gem("MyGem")

require "minitest/autorun"
require "my_gem"
```

Rails-only base classes are created through ActiveSupport load hooks. Configure LesliTesting before booting Rails; the shared classes and helpers are created when `rails/test_help` loads their corresponding Rails test classes:

```ruby
ENV["RAILS_ENV"] ||= "test"
require "lesli_testing"
LesliTesting.app("MyApplication")

require_relative "../config/environment"
require "rails/test_help"
```

LesliTesting can still be required by a standalone Ruby gem without Rails. Rails-only files and test classes are optional in that mode.

Rails engines should use the setup and Rails runner commands documented in [Testing Rails engines](/gems/testing/testing/engines). Do not execute an engine test file directly with Ruby when it inherits from a shared LesliTesting Rails class.

This order lets coverage observe application boot code while keeping Rails-specific test classes deferred until the Rails testing framework is ready.

See [Load order and process behavior](/gems/testing/about/execution) for the
complete initialization lifecycle, environment variables, and exit-code
contract.

## Next steps

- [Configure a Rails application](/gems/testing/testing/applications)
- [Configure a Rails engine](/gems/testing/testing/engines)
- [Configure a Ruby gem](/gems/testing/testing/gems)
