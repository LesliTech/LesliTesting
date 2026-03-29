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


# Load code coverage tools
require "simplecov"
require "simplecov-console"
require "simplecov-cobertura"


# Load test frameworks
require "minitest/lesli_testing_plugin"
require_relative "reporters/cli_reporter"

# Force Minitest to know about Lesli Minitest reporter plugin
unless Minitest.extensions.include?("lesli_testing")
    Minitest.register_plugin("lesli_testing") 
end

# Load test configuration and test helper modules
require_relative "coverage"
require_relative "testers"
require_relative "config"

module LesliTesting
    class Error < StandardError; end

    class << self

        def start_coverage!(engine_module = nil, options = {})
            return if defined?(SimpleCov) && SimpleCov.running

            name = engine_module ? engine_module.name : "RailsApp"

            # Start Coverage
            LesliTesting::Coverage.start(name, options[:min_coverage] || 40)
        end

        def configure_tests!(engine_module = nil)

            # Apply Minitest/Reporters/Paths
            LesliTesting::Config.apply(engine_module)
        end
    end
end
