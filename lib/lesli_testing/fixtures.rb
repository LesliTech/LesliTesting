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
    module Fixtures
        class << self
            def install!
                return if @installed

                ActiveSupport.on_load(
                    :active_support_test_case,
                    run_once: true,
                    yield: true
                ) do |test_case|
                    configure_lesli_fixtures(test_case)
                end

                @installed = true
            end

            def load_fixtures_for_engine(engine_module)
            end

            private

            def configure_lesli_fixtures(test_case)
                return unless defined?(Lesli::Engine)

                if defined?(ActiveRecord::TestFixtures)
                    test_case.include(ActiveRecord::TestFixtures)
                end

                lesli_fixtures = Lesli::Engine.root.join("test", "fixtures").to_s
                lesli_files = Lesli::Engine.root.join("test", "fixtures", "files").to_s

                if test_case.respond_to?(:fixture_paths=)
                    current_paths = if test_case.respond_to?(:fixture_paths)
                        Array(test_case.fixture_paths)
                    else
                        []
                    end
                    test_case.fixture_paths = current_paths | [lesli_fixtures]
                elsif test_case.respond_to?(:class_attribute)
                    test_case.class_attribute :fixture_paths, default: [lesli_fixtures]
                end

                if test_case.respond_to?(:file_fixture_path=)
                    test_case.file_fixture_path = lesli_files
                end

                if test_case.respond_to?(:set_fixture_class)
                    test_case.set_fixture_class(
                        lesli_users:    "Lesli::User",
                        lesli_accounts: "Lesli::Account"
                    )
                end
            end
        end
    end
end
