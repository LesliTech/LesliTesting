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
    module Fixtures
        LESLI_FIXTURE_CLASSES = {
            lesli_users: "Lesli::User",
            lesli_accounts: "Lesli::Account"
        }.freeze

        class << self
            def install!(profile: "app", engine_name: nil, options: {})
                @configuration = build_configuration(profile, engine_name, options)
                return if @installed

                ActiveSupport.on_load(
                    :active_support_test_case,
                    run_once: true,
                    yield: true
                ) do |test_case|
                    configure_test_case(test_case, load_sets: true)
                end

                ActiveSupport.on_load(
                    :action_dispatch_integration_test,
                    run_once: true,
                    yield: true
                ) do |test_case|
                    configure_test_case(test_case, load_sets: false)
                end

                ActiveSupport.on_load(
                    :active_record,
                    run_once: true,
                    yield: true
                ) do
                    configure_migration_paths
                end

                @installed = true
            end

            def load_fixtures_for_engine(engine_module, test_case: nil)
                test_case ||= ActiveSupport::TestCase if defined?(ActiveSupport::TestCase)
                raise ArgumentError, "A Rails test case is required" unless test_case

                configure_test_case(
                    test_case,
                    engine_module: engine_module,
                    load_sets: true
                )
            end

            def configure_migration_paths(application = nil)
                configuration = @configuration
                return [] unless configuration
                return [] unless configuration[:profile] == "engine"
                return [] unless configuration[:migrations][:enabled]

                application ||= Rails.application if defined?(Rails.application)
                paths = migration_paths(application)

                add_application_migration_paths(application, paths)
                add_active_record_migration_paths(paths)

                paths
            end

            private

            def build_configuration(profile, engine_name, options)
                fixture_options = options.fetch(:fixtures, {})
                migration_options = options.fetch(:migrations, {})
                default_shared = default_shared_engines(profile, engine_name)

                {
                    profile: profile,
                    fixtures: build_fixture_configuration(
                        fixture_options,
                        profile,
                        engine_name,
                        default_shared
                    ),
                    migrations: build_migration_configuration(
                        migration_options,
                        engine_name,
                        default_shared
                    )
                }
            end

            def build_fixture_configuration(options, profile, engine_name, default_shared)
                return { enabled: false } if options == false

                default_owner = engine_name if profile == "engine"
                owner = options.fetch(:owner, default_owner)
                shared = Array(options.fetch(:shared, default_shared))
                default_classes = if includes_lesli_fixtures?(owner, shared)
                    LESLI_FIXTURE_CLASSES
                else
                    {}
                end

                {
                    enabled: true,
                    owner: owner,
                    path: options[:path],
                    file_path: options[:file_path],
                    shared: shared,
                    shared_paths: Array(options[:shared_paths]),
                    sets: options.fetch(:sets, profile == "engine" ? :all : nil),
                    classes: default_classes.merge(options.fetch(:classes, {}))
                }
            end

            def build_migration_configuration(options, engine_name, default_shared)
                return { enabled: false } if options == false

                {
                    enabled: true,
                    owner: options.fetch(:owner, engine_name),
                    include_dummy: options.fetch(:include_dummy, true),
                    include_owner: options.fetch(:include_owner, true),
                    shared: Array(options.fetch(:shared, default_shared)),
                    paths: Array(options[:paths])
                }
            end

            def default_shared_engines(profile, engine_name)
                return ["Lesli"] if profile == "app"
                return [] unless profile == "engine"
                return [] if engine_name.to_s == "Lesli"

                ["Lesli"]
            end

            def includes_lesli_fixtures?(owner, shared)
                [owner, *shared].any? do |reference|
                    ["Lesli", "Lesli::Engine"].include?(reference.to_s)
                end
            end

            def configure_test_case(test_case, engine_module: nil, load_sets:)
                configuration = @configuration
                return [] unless configuration

                fixture_configuration = configuration[:fixtures]
                return [] unless fixture_configuration[:enabled]

                owner_engine = engine_module || resolve_engine(fixture_configuration[:owner])
                configured_paths = fixture_paths(owner_engine, fixture_configuration)

                include_active_record_fixtures(test_case)
                assign_fixture_paths(test_case, configured_paths, configuration[:profile])
                assign_file_fixture_path(test_case, owner_engine, fixture_configuration)
                configure_fixture_sets(test_case, fixture_configuration) if load_sets

                configured_paths
            end

            def include_active_record_fixtures(test_case)
                return unless defined?(ActiveRecord::TestFixtures)
                return if test_case < ActiveRecord::TestFixtures

                test_case.include(ActiveRecord::TestFixtures)
            end

            def fixture_paths(owner_engine, configuration)
                paths = []
                paths << expand_path(configuration[:path]) if configuration[:path]
                paths << engine_path(owner_engine, "test", "fixtures") unless configuration[:path]

                configuration[:shared].each do |shared_engine|
                    paths << engine_path(resolve_engine(shared_engine), "test", "fixtures")
                end

                paths.concat(configuration[:shared_paths].map { |path| expand_path(path) })
                paths.compact.uniq
            end

            def assign_fixture_paths(test_case, configured_paths, profile)
                if test_case.respond_to?(:fixture_paths=)
                    current_paths = if test_case.respond_to?(:fixture_paths)
                        Array(test_case.fixture_paths)
                    else
                        []
                    end

                    paths = if profile == "engine"
                        configured_paths + current_paths
                    else
                        current_paths + configured_paths
                    end
                    test_case.fixture_paths = paths.compact.uniq
                elsif test_case.respond_to?(:class_attribute)
                    test_case.class_attribute :fixture_paths, default: configured_paths
                end
            end

            def assign_file_fixture_path(test_case, owner_engine, configuration)
                return unless test_case.respond_to?(:file_fixture_path=)

                file_path = configuration[:file_path]
                file_path ||= engine_path(owner_engine, "test", "fixtures", "files") if owner_engine
                test_case.file_fixture_path = expand_path(file_path) if file_path
            end

            def configure_fixture_sets(test_case, configuration)
                if test_case.respond_to?(:set_fixture_class) && configuration[:classes].any?
                    test_case.set_fixture_class(configuration[:classes])
                end

                sets = configuration[:sets]
                return unless sets
                return unless test_case.respond_to?(:fixtures)

                sets == :all ? test_case.fixtures(:all) : test_case.fixtures(*Array(sets))
            end

            def migration_paths(application)
                configuration = @configuration[:migrations]
                paths = []

                if configuration[:include_dummy] && application&.respond_to?(:root)
                    paths << File.join(application.root.to_s, "db", "migrate")
                end

                if configuration[:include_owner]
                    paths << engine_path(resolve_engine(configuration[:owner]), "db", "migrate")
                end

                configuration[:shared].each do |shared_engine|
                    paths << engine_path(resolve_engine(shared_engine), "db", "migrate")
                end

                paths.concat(configuration[:paths].map { |path| expand_path(path) })
                paths.compact.select { |path| Dir.exist?(path) }.uniq
            end

            def add_application_migration_paths(application, paths)
                return unless application&.respond_to?(:config)

                rails_paths = application.config.paths["db/migrate"]
                return unless rails_paths

                registered_paths = rails_paths.expanded.map { |path| expand_path(path) }
                paths.each do |path|
                    expanded_path = expand_path(path)
                    next if registered_paths.include?(expanded_path)

                    rails_paths << path
                    registered_paths << expanded_path
                end
            end

            def add_active_record_migration_paths(paths)
                return unless defined?(ActiveRecord::Migrator)
                return unless ActiveRecord::Migrator.respond_to?(:migrations_paths=)

                current_paths = if ActiveRecord::Migrator.respond_to?(:migrations_paths)
                    Array(ActiveRecord::Migrator.migrations_paths)
                else
                    []
                end
                registered_paths = current_paths.map { |path| expand_path(path) }
                missing_paths = paths.reject do |path|
                    registered_paths.include?(expand_path(path))
                end

                ActiveRecord::Migrator.migrations_paths = current_paths + missing_paths
            end

            def resolve_engine(reference)
                return reference if reference.respond_to?(:root)
                return if reference.nil?

                constant = constantize(reference.to_s)
                return constant if constant&.respond_to?(:root)
                return unless constant&.const_defined?(:Engine)

                constant.const_get(:Engine)
            end

            def constantize(name)
                name.split("::").reject(&:empty?).inject(Object) do |namespace, constant_name|
                    namespace.const_get(constant_name)
                end
            rescue NameError
                nil
            end

            def engine_path(engine_module, *parts)
                return unless engine_module&.respond_to?(:root)

                File.join(engine_module.root.to_s, *parts)
            end

            def expand_path(path)
                File.expand_path(path.to_s)
            end
        end
    end
end
