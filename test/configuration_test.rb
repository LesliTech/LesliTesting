# frozen_string_literal: true

require "open3"
require "rbconfig"
require_relative "test_helper"

class ConfigurationTest < Minitest::Test
    PROJECT_ROOT = File.expand_path("..", __dir__)
    LIB_PATH = File.join(PROJECT_ROOT, "lib")

    def test_app_selects_app_coverage_profile_and_registers_rails_hooks
        assert_profile(:app, "lesli_rails_app", fake_rails: :hooks)
    end

    def test_engine_selects_engine_coverage_profile_and_loads_railtie
        assert_profile(:engine, "lesli_rails_engine", fake_rails: :engine)
    end

    def test_engine_railtie_uses_the_configured_target_only_in_test
        script = <<~'RUBY'
            module ActiveSupport
                HOOKS = Hash.new { |hash, key| hash[key] = [] }

                def self.on_load(name, **options, &block)
                    HOOKS[name] << block
                end
            end

            module Rails
                class Environment
                    def initialize(name)
                        @name = name
                    end

                    def test?
                        @name == "test"
                    end
                end

                class << self
                    attr_accessor :env
                end

                class Engine
                    class << self
                        def initializer(name, **options, &block)
                            initializer_blocks[name] = block
                        end

                        def initializer_blocks
                            @initializer_blocks ||= {}
                        end
                    end
                end
            end

            $LOADED_FEATURES << "active_support/lazy_load_hooks.rb"
            $LOADED_FEATURES << "rails.rb"
            $LOADED_FEATURES << "rails/engine.rb"

            require "lesli_testing"
            LesliTesting.engine("DisplayName", engine: "TargetEngine")

            calls = []
            LesliTesting::Fixtures.define_singleton_method(:configure_migration_paths) do |application, engine_target:|
                calls << [application, engine_target]
            end

            application = Object.new
            initializer = LesliTesting::Engine.initializer_blocks.fetch(
                "lesli_testing.load_required_migrations"
            )

            Rails.env = Rails::Environment.new("development")
            initializer.call(application)
            abort "Railtie changed migrations outside test" unless calls.empty?

            Rails.env = Rails::Environment.new("test")
            initializer.call(application)

            abort "Wrong configured target" unless LesliTesting::Engine.engine_target == "TargetEngine"
            abort "Target was not passed to migrations" unless calls == [[application, "TargetEngine"]]
        RUBY

        assert_child_success(script, coverage: false)
    end

    def test_gem_selects_gem_coverage_profile_without_loading_rails
        assert_profile(:gem, "lesli_rails_gem", forbid_rails: true)
    end

    def test_coverage_starts_only_once
        script = <<~RUBY
            require "lesli_testing"
            require "simplecov"

            starts = 0
            original_start = SimpleCov.method(:start)
            SimpleCov.define_singleton_method(:start) do |profile = nil, &block|
                starts += 1
                original_start.call(profile, &block)
            end

            LesliTesting.gem("FirstRun", coverage_min_coverage: 0)
            LesliTesting.gem("SecondRun", coverage_min_coverage: 0)

            abort "Coverage started \#{starts} times" unless starts == 1
            SimpleCov.at_exit { }
        RUBY

        assert_child_success(script, coverage: true)
    end

    private

    def assert_profile(api, expected_profile, fake_rails: nil, forbid_rails: false)
        rails_setup = case fake_rails
        when :hooks
            fake_active_support
        when :engine
            [fake_active_support, fake_rails_engine].join("\n")
        else
            ""
        end

        rails_guard = if forbid_rails
            <<~RUBY
                module Kernel
                    alias lesli_testing_original_require require

                    def require(feature)
                        if feature.start_with?("rails", "active_support", "action_dispatch", "action_view")
                            raise "Rails dependency loaded by gem profile: \#{feature}"
                        end

                        lesli_testing_original_require(feature)
                    end
                end
            RUBY
        else
            ""
        end

        profile_assertions = case api
        when :app
            <<~RUBY
                abort "Rails integration missing" unless $LOADED_FEATURES.any? { |path| path.end_with?("lesli_testing/rails_integration.rb") }
                abort "Engine Railtie loaded for app profile" if $LOADED_FEATURES.any? { |path| path.end_with?("lesli_testing/engine.rb") }
                abort "Rails hooks were not registered" unless ActiveSupport::HOOKS.key?(:active_support_test_case)
            RUBY
        when :engine
            <<~RUBY
                abort "Engine Railtie missing" unless $LOADED_FEATURES.any? { |path| path.end_with?("lesli_testing/engine.rb") }
                abort "Engine initializer missing" unless LesliTesting::Engine.initializers.include?("lesli_testing.load_required_migrations")
                abort "Wrong engine target" unless LesliTesting::Engine.engine_target == "ExampleProject"
                abort "Rails hooks were not registered" unless ActiveSupport::HOOKS.key?(:active_support_test_case)
            RUBY
        when :gem
            <<~RUBY
                abort "Rails integration loaded for gem profile" if $LOADED_FEATURES.any? { |path| path.end_with?("lesli_testing/rails_integration.rb") }
            RUBY
        end

        script = <<~RUBY
            #{rails_setup}

            require "lesli_testing"
            require "simplecov"

            selected_profiles = []
            original_start = SimpleCov.method(:start)
            SimpleCov.define_singleton_method(:start) do |profile = nil, &block|
                selected_profiles << profile
                original_start.call(profile, &block)
            end

            #{rails_guard}

            LesliTesting.public_send(
                :#{api},
                "ExampleProject",
                coverage_min_coverage: 37,
                coverage_missing_len: 12
            )

            abort "Wrong profile: \#{selected_profiles.inspect}" unless selected_profiles == ["#{expected_profile}"]
            abort "Wrong command name" unless SimpleCov.command_name == "ExampleProject"
            abort "Wrong minimum coverage" unless SimpleCov.minimum_coverage == { line: 37 }
            abort "Wrong missing length" unless SimpleCov::Formatter::Console.missing_len == 12
            abort "Wrong project name" unless LesliTesting.app_name == "ExampleProject"
            abort "Wrong project profile" unless LesliTesting.profile == "#{api}"
            abort "Wrong public API profile" unless LesliTesting.send(:options)[:coverage_profile] == "#{api}"

            #{profile_assertions}

            SimpleCov.at_exit { }
        RUBY

        assert_child_success(script, coverage: true)
    end

    def fake_active_support
        <<~RUBY
            module ActiveSupport
                HOOKS = Hash.new { |hash, key| hash[key] = [] }

                def self.on_load(name, **options, &block)
                    HOOKS[name] << block
                end
            end

            $LOADED_FEATURES << "active_support/lazy_load_hooks.rb"
        RUBY
    end

    def fake_rails_engine
        <<~RUBY
            module Rails
                class Engine
                    class << self
                        def initializer(name, **options, &block)
                            initializers << name
                        end

                        def initializers
                            @initializers ||= []
                        end
                    end
                end
            end

            $LOADED_FEATURES << "rails.rb"
            $LOADED_FEATURES << "rails/engine.rb"
        RUBY
    end

    def assert_child_success(script, coverage:)
        stdout, stderr, status = Open3.capture3(
            { "COVERAGE" => coverage ? "true" : nil },
            RbConfig.ruby,
            "-I#{LIB_PATH}",
            "-e",
            script,
            chdir: PROJECT_ROOT
        )

        assert status.success?, [stdout, stderr].join("\n")
    end
end
