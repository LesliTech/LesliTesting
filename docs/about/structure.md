# Project and gem structure

LesliTesting does not generate files or impose a custom test layout. It works with conventional Rails and Ruby gem structures.

## Rails application structure

```text
my_application/
├── app/
├── config/
├── lib/
├── test/
│   ├── controllers/
│   ├── fixtures/
│   │   └── files/
│   ├── helpers/
│   ├── integration/
│   ├── models/
│   ├── system/
│   └── test_helper.rb
└── Gemfile
```

Configure `LesliTesting.app` in `test/test_helper.rb`. Rails continues to discover tests and fixtures using its normal conventions.

## Rails engine structure

```text
my_engine/
├── app/
├── config/
├── db/
│   └── migrate/
├── lib/
│   ├── my_engine.rb
│   └── my_engine/
│       ├── engine.rb
│       └── version.rb
├── test/
│   ├── dummy/
│   │   ├── app/
│   │   │   ├── controllers/
│   │   │   │   └── application_controller.rb
│   │   │   └── models/
│   │   │       └── application_record.rb
│   │   ├── config/
│   │   │   └── environments/
│   │   │       └── test.rb
│   │   ├── db/
│   │   └── Rakefile
│   ├── fixtures/
│   │   └── files/
│   ├── integration/
│   ├── models/
│   ├── test_helper.rb
│   └── my_engine_test.rb
├── my_engine.gemspec
└── Rakefile
```

The dummy application supplies the Rails runtime used by the engine tests. Keep the complete Rails-generated dummy structure: eager loading and dependencies may require host constants such as top-level `ApplicationController` and `ApplicationRecord` even when ordinary local tests do not reference them. Configure `LesliTesting.engine` in the engine's `test/test_helper.rb`.

## Standalone Ruby gem structure

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

Configure `LesliTesting.gem` before requiring the gem's main file so that coverage observes its source.

## LesliTesting repository structure

The main implementation is organized by responsibility:

```text
LesliTesting/
├── docs/
│   ├── images/
│   └── *.md
├── lib/
│   ├── minitest/
│   │   └── lesli_testing_plugin.rb
│   ├── lesli_testing.rb
│   └── lesli_testing/
│       ├── helpers/
│       │   └── response_integration_helper.rb
│       ├── minitest/
│       │   └── cli_reporter.rb
│       ├── simplecov/
│       │   └── profiles.rb
│       ├── coverage.rb
│       ├── engine.rb
│       ├── fixtures.rb
│       ├── testers.rb
│       └── version.rb
├── test/
│   ├── test_helper.rb
│   ├── demo_test.rb
│   └── performance_test.rb
├── lesli_testing.gemspec
└── Rakefile
```

| Path | Responsibility |
| --- | --- |
| `lib/lesli_testing.rb` | Minimal entrypoint that starts native Ruby coverage before loading the implementation. |
| `lib/lesli_testing/core.rb` | Public `app`, `engine`, and `gem` API and phased initialization coordinator. |
| `lib/lesli_testing/rails_integration.rb` | Registers the optional Railtie and deferred Rails test integrations. |
| `lib/minitest/lesli_testing_plugin.rb` | Registers the custom reporter with Minitest. |
| `lib/lesli_testing/minitest/cli_reporter.rb` | Per-test output, summaries, and failure formatting. |
| `lib/lesli_testing/coverage.rb` | Starts SimpleCov and configures its formatters and threshold. |
| `lib/lesli_testing/simplecov/profiles.rb` | Application, engine, and gem coverage profiles. |
| `lib/lesli_testing/engine.rb` | Rails initializer that applies the configured dummy, owner, and shared engine migration paths. |
| `lib/lesli_testing/testers.rb` | Defines shared Rails test base classes through ActiveSupport load hooks. |
| `lib/lesli_testing/fixtures.rb` | Applies owner and shared fixtures through Rails load hooks and de-duplicates migration paths. |
| `lib/lesli_testing/helpers/response_integration_helper.rb` | JSON response helpers loaded only with the Rails integration test base. |
| `test/demo_test.rb` | Intentional failures for visually inspecting reporter output. |
| `test/performance_test.rb` | Lightweight reporter execution tests. |

See [Testing tools](/gems/testing/about/tools) for the behavior exposed by these components.
