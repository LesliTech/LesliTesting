=begin

Lesli

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

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

# Load code coverage tools
require "simplecov"
require "simplecov-console"
require "simplecov-cobertura"
require_relative "simplecov/profiles"


module LesliTesting
    module Coverage
        def self.start(engine_name = "Lesli", profile:"rails", min_coverage:90, missing_len:25)
            return unless ENV["COVERAGE"]

            # Add coverage formatters 
            SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                SimpleCov::Formatter::CoberturaFormatter,
                SimpleCov::Formatter::HTMLFormatter,
                SimpleCov::Formatter::Console
            ])

            # Define the limit to allow missing tested code
            SimpleCov::Formatter::Console.missing_len = missing_len

            SimpleCov.start "lesli_rails_#{profile}" do

                command_name(engine_name)

                # Minimum expected coverage percentage
                minimum_coverage(min_coverage)
            end
        end
    end
end
