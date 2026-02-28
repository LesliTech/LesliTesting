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

module LesliTesting
    module Coverage
        def self.start(engine_name = "Lesli", min_coverage = 40)
            return unless ENV["COVERAGE"]

            # Add coverage formatters 
            SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                SimpleCov::Formatter::CoberturaFormatter,
                SimpleCov::Formatter::Console
            ])

            # Define the limit to allow missing tested code
            SimpleCov::Formatter::Console.missing_len = 10

            SimpleCov.start do
                self.command_name engine_name

                # Standard filters for all Lesli engines
                add_filter [
                    "/app/assets", 
                    "/app/jobs", 
                    "/config", 
                    "/db", 
                    "/lib/test", 
                    "/test", 
                    "/vendor"
                ]

                # Add your groups
                add_group "Models", "app/models"
                add_group "Operators", "app/operators"
                add_group "Validators", "app/validators"
                add_group "Controllers", "app/controllers"
            end

            # Minimum expected coverage percentage
            SimpleCov.minimum_coverage min_coverage
        end
    end
end
