# frozen_string_literal: true

require "active_support/lazy_load_hooks"
require_relative "testers"
require_relative "fixtures"

module LesliTesting
    module RailsIntegration
        class << self
            def install!(profile:, project_name:, engine_target: nil, options:)
                LesliTesting::Fixtures.install!(
                    profile: profile,
                    engine_name: engine_target || project_name,
                    options: options
                )
                install_engine!(engine_target || project_name) if profile == "engine"
                LesliTesting::Testers.install!
            end

            private

            def install_engine!(engine_target)
                require "rails"
                require "rails/engine"
                require_relative "engine"

                LesliTesting::Engine.configure(engine_target: engine_target)
            end
        end
    end
end
