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

The dummy application supplies the Rails runtime used by the engine tests. Configure `LesliTesting.engine` in the engine's `test/test_helper.rb`.

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
| `lib/lesli_testing.rb` | Public `app`, `engine`, and `gem` configuration API. |
| `lib/minitest/lesli_testing_plugin.rb` | Registers the custom reporter with Minitest. |
| `lib/lesli_testing/minitest/cli_reporter.rb` | Per-test output, summaries, and failure formatting. |
| `lib/lesli_testing/coverage.rb` | Starts SimpleCov and configures its formatters and threshold. |
| `lib/lesli_testing/simplecov/profiles.rb` | Application, engine, and gem coverage profiles. |
| `lib/lesli_testing/engine.rb` | Rails initializer source for adding Lesli migration paths when this optional file is loaded. |
| `lib/lesli_testing/testers.rb` | Shared Rails test base classes. |
| `lib/lesli_testing/fixtures.rb` | Shared Lesli fixture integration. |
| `lib/lesli_testing/helpers/response_integration_helper.rb` | JSON integration-response assertions and parsing. |
| `test/demo_test.rb` | Intentional failures for visually inspecting reporter output. |
| `test/performance_test.rb` | Lightweight reporter execution tests. |

See [Testing tools](./tools.md) for the behavior exposed by these components.
