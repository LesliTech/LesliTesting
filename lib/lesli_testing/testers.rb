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


#
require_relative "helpers/response_integration_helper"

#
module LesliTesting

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
end
