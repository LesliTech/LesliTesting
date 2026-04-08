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
            def load_fixtures_for_lesli()

                if defined?(Lesli)
                    ActiveSupport.on_load(:active_support_test_case) do
                        # En Rails 8, usamos ActiveRecord::TestFixtures si está disponible
                        include ActiveRecord::TestFixtures if defined?(ActiveRecord::TestFixtures)

                        lesli_fixtures = Lesli::Engine.root.join("test", "fixtures").to_s
                        lesli_files = Lesli::Engine.root.join("test", "fixtures", "files").to_s

                        # Rails 8 usa fixture_paths (plural) como el estándar
                        # Pero para evitar el NoMethodError, lo asignamos de forma segura:
                        if respond_to?(:fixture_paths=)
                            # Combinamos las rutas existentes con la nueva del Engine
                            self.fixture_paths |= [ lesli_fixtures ]
                        else
                            # Fallback por si la carga de ActiveRecord se retrasa
                            class_attribute :fixture_paths, default: [ lesli_fixtures ]
                        end

                        # Los archivos adjuntos (Active Storage, etc)
                        self.file_fixture_path = lesli_files

                        # IMPORTANT: attach fixture sets to namespaced models BEFORE loading fixtures
                        self.set_fixture_class(
                            lesli_users:    "Lesli::User",
                            lesli_accounts: "Lesli::Account"
                        )
                    end
                end
            end

            def load_fixtures_for_engine(engine_module)
            end
        end
    end
end
