# Testing profiles

LesliTesting configures one shared Minitest workflow for three project shapes. Select exactly one profile in `test/test_helper.rb` before requiring the code being measured.

| Profile | Use for | Guide |
| --- | --- | --- |
| `LesliTesting.app(name, options)` | A full Rails application or Lesli workspace | [Applications](/gems/testing/testing/applications) |
| `LesliTesting.engine(name, options)` | An isolated or mountable Rails engine | [Engines](/gems/testing/testing/engines) |
| `LesliTesting.gem(name, options)` | A standalone Ruby gem | [Gems](/gems/testing/testing/gems) |

All profiles configure the custom Minitest reporter. When `COVERAGE` is present they also start the matching SimpleCov profile and produce console, HTML, and Cobertura output.

Start with [Installation and configuration](/gems/testing/about/installation), then choose the guide for the repository being tested. [Testing tools](/gems/testing/about/tools) documents coverage options, shared test classes, response helpers, and fixture integration.
