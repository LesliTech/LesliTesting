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
    module Testers
        class << self
            def install!
                return if @installed

                ActiveSupport.on_load(
                    :action_dispatch_integration_test,
                    run_once: true,
                    yield: true
                ) do |test_case|
                    define_integration_tester(test_case)
                end

                ActiveSupport.on_load(
                    :action_view_test_case,
                    run_once: true,
                    yield: true
                ) do |test_case|
                    define_view_tester(test_case)
                end

                ActiveSupport.on_load(
                    :active_support_test_case,
                    run_once: true,
                    yield: true
                ) do |test_case|
                    define_model_tester(test_case)
                    load_rails_test_cases
                end

                @installed = true
            end

            private

            def define_integration_tester(test_case)
                return if LesliTesting.const_defined?(:IntegrationTester, false)

                require_relative "helpers/response_integration_helper"

                tester = Class.new(test_case) do
                    include LesliTesting::ResponseIntegrationHelper
                end
                LesliTesting.const_set(:IntegrationTester, tester)
            end

            def define_view_tester(test_case)
                return if LesliTesting.const_defined?(:ViewTester, false)

                tester = Class.new(test_case) do
                    def self.inherited(subclass)
                        super
                        subclass.class_eval do
                            include Lesli::HtmlHelper   if defined?(Lesli::HtmlHelper)
                            include Lesli::SystemHelper if defined?(Lesli::SystemHelper)
                        end
                    end
                end
                LesliTesting.const_set(:ViewTester, tester)
            end

            def define_model_tester(test_case)
                return if LesliTesting.const_defined?(:ModelTester, false)

                require "active_support/testing/time_helpers"

                tester = Class.new(test_case) do
                    include ActiveSupport::Testing::TimeHelpers
                end
                LesliTesting.const_set(:ModelTester, tester)
            end

            def load_rails_test_cases
                require "action_dispatch/testing/integration"
                require "action_view/test_case"
            end
        end
    end
end
