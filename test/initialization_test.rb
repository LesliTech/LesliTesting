# frozen_string_literal: true

require "open3"
require "rbconfig"
require_relative "test_helper"

class InitializationTest < Minitest::Test
    PROJECT_ROOT = File.expand_path("..", __dir__)
    LIB_PATH = File.join(PROJECT_ROOT, "lib")

    def test_require_only_loads_the_core_phase
        script = <<~RUBY
            require "lesli_testing"

            forbidden = %w[
                minitest.rb
                termline.rb
                lesli_testing/coverage.rb
                lesli_testing/rails_integration.rb
                lesli_testing/testers.rb
                lesli_testing/fixtures.rb
                lesli_testing/helpers/response_integration_helper.rb
            ]

            loaded = forbidden.select do |suffix|
                $LOADED_FEATURES.any? { |feature| feature.end_with?(suffix) }
            end

            abort "Loaded too early: \#{loaded.join(', ')}" unless loaded.empty?
            abort "Coverage started without COVERAGE" if defined?(::Coverage) && ::Coverage.running?
        RUBY

        assert_child_success(script)
    end

    def test_coverage_starts_only_for_explicit_true_values
        enabled_script = <<~RUBY
            require "lesli_testing"
            abort "Coverage was not started" unless defined?(::Coverage) && ::Coverage.running?
        RUBY

        disabled_script = <<~RUBY
            require "lesli_testing"
            abort "Coverage was started" if defined?(::Coverage) && ::Coverage.running?
        RUBY

        %w[true 1 yes].each do |value|
            assert_child_success(enabled_script, environment: { "COVERAGE" => value })
        end

        %w[false 0 no].each do |value|
            assert_child_success(disabled_script, environment: { "COVERAGE" => value })
        end
    end

    def test_gem_profile_loads_reporter_without_rails_integrations
        script = <<~RUBY
            require "lesli_testing"
            LesliTesting.gem("ExampleGem")

            abort "Reporter plugin was not registered" unless Minitest.extensions.include?("lesli_testing")

            forbidden = %w[
                lesli_testing/rails_integration.rb
                lesli_testing/testers.rb
                lesli_testing/fixtures.rb
                lesli_testing/helpers/response_integration_helper.rb
            ]

            loaded = forbidden.select do |suffix|
                $LOADED_FEATURES.any? { |feature| feature.end_with?(suffix) }
            end

            abort "Loaded Rails integration for a gem: \#{loaded.join(', ')}" unless loaded.empty?
        RUBY

        assert_child_success(script)
    end

    def test_rails_testers_are_defined_only_when_load_hooks_run
        script = <<~RUBY
            module ActiveSupport
                module Testing
                    module TimeHelpers
                    end
                end

                HOOKS = {}

                def self.on_load(name, **options, &block)
                    HOOKS[name] = block
                end
            end

            $LOADED_FEATURES << "active_support/testing/time_helpers.rb"
            $LOADED_FEATURES << "action_dispatch/testing/integration.rb"
            $LOADED_FEATURES << "action_view/test_case.rb"

            require "lesli_testing/testers"
            LesliTesting::Testers.install!

            abort "IntegrationTester loaded before Rails hook" if LesliTesting.const_defined?(:IntegrationTester, false)
            abort "ViewTester loaded before Rails hook" if LesliTesting.const_defined?(:ViewTester, false)
            abort "ModelTester loaded before Rails hook" if LesliTesting.const_defined?(:ModelTester, false)

            integration_base = Class.new
            view_base = Class.new
            model_base = Class.new

            ActiveSupport::HOOKS.fetch(:active_support_test_case).call(model_base)
            ActiveSupport::HOOKS.fetch(:action_view_test_case).call(view_base)

            helper_loaded = $LOADED_FEATURES.any? do |feature|
                feature.end_with?("lesli_testing/helpers/response_integration_helper.rb")
            end
            abort "Response helper loaded before integration hook" if helper_loaded

            ActiveSupport::HOOKS.fetch(:action_dispatch_integration_test).call(integration_base)

            abort "Wrong integration base" unless LesliTesting::IntegrationTester < integration_base
            abort "Wrong view base" unless LesliTesting::ViewTester < view_base
            abort "Wrong model base" unless LesliTesting::ModelTester < model_base
            abort "Response helper missing" unless LesliTesting::IntegrationTester < ResponseIntegrationHelper
        RUBY

        assert_child_success(script)
    end

    private

    def assert_child_success(script, environment: {})
        stdout, stderr, status = Open3.capture3(
            { "COVERAGE" => nil }.merge(environment),
            RbConfig.ruby,
            "-I#{LIB_PATH}",
            "-e",
            script,
            chdir: PROJECT_ROOT
        )

        assert status.success?, [stdout, stderr].join("\n")
    end
end
