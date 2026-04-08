<div align="center" class="documentation-header">
    <img width="100" alt="LesliTesting logo" src="./docs/images/testing-logo.svg" />
    <h3 align="center">Shared testing and coverage configuration for the Lesli Platform.</h3>
</div>

<br />
<hr/>
<br />


### Quick start

<br />


**Install LesliTesting gem**

```shell
bundle add lesli_testing
```

<br />
<br />

**Include LesliTesting in your test_helper.rb file**

```ruby
ENV["RAILS_ENV"] ||= "test"


# Load LesliTesting tools
require "lesli_testing"


# Configure leslitesting tools for a rails engine
LesliTesting.engine("LesliShield")


# Configure lesli testing tools for a rails app
LesliTesting.app("LesliBuilder")


# # Configure leslitesting tools for a ruby gem
LesliTesting.gem("LesliDate")
```

<br />
<br />

**Run your tests D:**

```shell
rails test

# or

COVERAGE=true rails test

# or run like github actions

COVERAGE=true CI=true rails test
```

<br />
<br />

**Result :D**

<div align="center">
    <img
        style="width:100%;max-width:800px;border-radius:6px;"
        alt="LesliTesting screenshot" src="./docs/images/screenshot.png" />
</div>

<br />
<br />

### Options

The following options can be used to customize coverage behavior in `LesliTesting`.

| Option                  | Type    | Default | Description                                |
| ----------------------- | ------- | ------: | ------------------------------------------ |
| `coverage_missing_len`  | Integer |    `25` | Minimum width for missing coverage output. |
| `coverage_min_coverage` | Integer |    `40` | Minimum expected coverage percentage.      |

**Example:**

```ruby
LesliTesting.configure(LesliShield, {
    coverage_missing_len: 30,
    coverage_min_coverage: 80
})
```

<br />
<br />

### Documentation
* [website](https://www.lesli.dev/)
* [documentation](https://www.lesli.dev/gems/testing/)


### Connect with Lesli

* [X: @LesliTech](https://x.com/LesliTech)
* [Email: hello@lesli.tech](hello@lesli.tech)
* [Website: https://www.lesli.tech](https://www.lesli.tech)


### License
-------
Copyright (c) 2026, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

<br />
<hr />
<br />
<br />

<div align="center" class="has-text-centered">
    <img width="80" alt="Lesli logo" src="https://cdn.lesli.tech/lesli/brand/app-icon.svg" />
    <h4 align="center" class="mt-0">
        The Open-Source SaaS Development Framework for Ruby on Rails.
    </h4>
</div>

<br />
<br />
