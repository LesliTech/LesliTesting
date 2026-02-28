# frozen_string_literal: true

# Lesli
# 
# Copyright (c) 2025, Lesli Technologies, S. A.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
# 
# Lesli · Ruby on Rails SaaS Development Framework.
# 
# Made with ♥ by LesliTech
# Building a better future, one line of code at a time.
# 
# @contact  hello@lesli.tech
# @website  https://www.lesli.tech
# @license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html
# 
# // · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
# // · 

#
require_relative "lesli_testing/version"

# Load test frameworks
require "minitest/reporters"
require "color_pound_spec_reporter"
require "propshaft"

# Load code coverage tools
require "simplecov"
require "simplecov-console"
require "simplecov-cobertura"


# Load test configuration and test helper modules
require_relative "lesli_testing/config"
require_relative "lesli_testing/coverage"
require_relative "lesli_testing/helpers/response_integration_helper"

module LesliTesting
    class Error < StandardError; end

    class IntegrationTester < ActionDispatch::IntegrationTest
        include ResponseIntegrationHelper
    end

    class ViewTester < ActionView::TestCase
        # We use a hook to include the helpers only when the class is used.
        # This ensures Lesli core is fully loaded by Rails before we ask for the helpers.
        def self.inherited(subclass)
            super
            subclass.class_eval do
                include Lesli::HtmlHelper   if defined?(Lesli::HtmlHelper)
                include Lesli::SystemHelper if defined?(Lesli::SystemHelper)
            end
        end
    end

    # Define the base classes inside the namespace
    class ModelTester < ActiveSupport::TestCase
        include ActiveSupport::Testing::TimeHelpers
    end

    class << self

        def init(engine_module = nil, options = {})
            # 1. Start Coverage
            name = engine_module ? engine_module.name : "RailsApp"
            LesliTesting::Coverage.start(name, options[:min_coverage] || 40)

            # 2. Apply Minitest/Reporters/Paths
            LesliTesting::Config.apply(engine_module)

            # 4. Notify
            show_welcome_message
        end

        private

        def show_welcome_message
            puts "\n\e[34mRunning Lesli tests...\e[0m"
            puts "For a better result run test over a clean database"
            puts "You can use: \e[33mrake dev:db:reset test\e[0m\n\n"
        end
    end
end
