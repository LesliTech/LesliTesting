# frozen_string_literal: true

require "active_support/lazy_load_hooks"
require_relative "testers"
require_relative "fixtures"

module LesliTesting
    module RailsIntegration
        class << self
            def install!(profile:, project_name:, options:)
                LesliTesting::Fixtures.install!(
                    profile: profile,
                    engine_name: project_name,
                    options: options
                )
                install_engine! if profile == "engine"
                LesliTesting::Testers.install!
            end

            private

            def install_engine!
                require "rails"
                require "rails/engine"
                require_relative "engine"
            end
        end
    end
end
