# frozen_string_literal: true

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


require_relative "lesli_testing/version"


module LesliTesting
    class Error < StandardError; end

    class << self

        attr_accessor :app_module; 
        attr_accessor :app_name; 
        attr_writer :options

        def app(name, options = {})
            configure(name, options.merge(coverage_profile: "app"))
        end

        def engine(name, options = {})
            configure(name, options.merge(coverage_profile: "engine"))
        end

        def gem(name, options = {})
            configure(name, options.merge(coverage_profile: "gem"))
        end

        private 

        def options
            @options ||= options_default
        end

        def options_default
            {
                coverage_profile: "app",
                coverage_missing_len: 25,
                coverage_min_coverage: 90
            }
        end

        def configure(name, options)
            self.app_name = name
            self.options = options_default.merge(options)
            configure_gems()
            configure_reporter()
            configure_coverage()
            configure_fixtures()
        end

        def configure_coverage()

            return unless ENV["COVERAGE"]
            return if defined?(SimpleCov) && SimpleCov.running            

            # Start Coverage
            LesliTesting::Coverage.start(
                self.app_name, 
                profile: self.options[:coverage_profile],
                missing_len: self.options[:coverage_missing_len],
                min_coverage: self.options[:coverage_min_coverage]
            )
        end 

        # Load test configuration and test helper modules
        def configure_fixtures()
            LesliTesting::Fixtures.load_fixtures_for_lesli()
        end

        def configure_reporter
            # Force Minitest to know about Lesli Minitest reporter plugin
            unless Minitest.extensions.include?("lesli_testing")
                Minitest.register_plugin("lesli_testing") 
            end
        end

        def configure_gems
            return if @tools_loaded

            #require "minitest"

            # Load minitest plugin
            require "minitest/lesli_testing_plugin"
            require "termline" unless defined?(Termline)

            # Load helper files
            require_relative "lesli_testing/testers"
            require_relative "lesli_testing/fixtures"
            require_relative "lesli_testing/coverage"

            @tools_loaded = true
        end
    end
end
