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
require "minitest/reporters"
require "color_pound_spec_reporter"


# Load test configuration and test helper modules
require_relative "config"
require_relative "coverage"
require_relative "testers"

module LesliTesting
    class Error < StandardError; end

    class << self

        def load(engine_module = nil, options = {})

            name = engine_module ? engine_module.name : "RailsApp"

            # 1. Notify
            show_welcome_message

            # 2. Start Coverage
            LesliTesting::Coverage.start(name, options[:min_coverage] || 40)

            # 3. Apply Minitest/Reporters/Paths
            LesliTesting::Config.apply(engine_module)
        end

        private

        def show_welcome_message
            L2.info(
                "Running Lesli tests...",
                "For a better result run test over a clean database",
                "You can use: rake dev:db:reset")

            L2.br
        end
    end
end
