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
    module Config
        def self.apply(engine_module = nil)
            
            # Workaround for color_pound_spec_reporter
            Object.const_set(:MiniTest, Minitest) unless defined?(MiniTest)

            # Load dummy app for unit testing
            # Run tests across all the engines: LESLI_INTEGRATION_TEST=true rails test
            # Run tests for the current engine: rails test
            if engine_module
                # Migration and Fixture logic goes here...
                ActiveRecord::Migrator.migrations_paths = [engine_module.root.join("db/migrate").to_s] if defined?(ActiveRecord)
                ActiveRecord::Migrator.migrations_paths = [engine_module.root.join("db/migrate/1.0").to_s] if defined?(ActiveRecord)


                # Load fixtures from the engine
                if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
                    ActiveSupport::TestCase.fixture_paths = [ engine_module.root.join("test", "fixtures").to_s ]
                    ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
                    ActiveSupport::TestCase.file_fixture_path = engine_module.root.join("test", "fixtures", "files").to_s

                    # IMPORTANT: attach fixture sets to namespaced models BEFORE loading fixtures
                    ActiveSupport::TestCase.set_fixture_class(
                        lesli_users:    "Lesli::User",
                        lesli_accounts: "Lesli::Account"
                    )

                    ActiveSupport::TestCase.fixtures :all
                end
            end

            Minitest::Reporters.use!([
                Minitest::Reporters::DefaultReporter.new(color: true),
                Minitest::Reporters::JUnitReporter.new("coverage/reports"),
                ColorPoundSpecReporter.new
            ])

        end
    end
end
