# frozen_string_literal: true

require "open3"
require "rbconfig"
require_relative "test_helper"

class FixturesTest < Minitest::Test
    PROJECT_ROOT = File.expand_path("..", __dir__)
    LIB_PATH = File.join(PROJECT_ROOT, "lib")

    def test_engine_fixtures_and_migrations_are_configured_after_rails_loads
        script = <<~'RUBY'
            require "fileutils"
            require "tmpdir"

            module ActiveSupport
                HOOKS = {}

                def self.on_load(name, **options, &block)
                    HOOKS[name] = block
                end
            end

            module ActiveRecord
                module TestFixtures
                end

                class Migrator
                    class << self
                        attr_accessor :migrations_paths
                    end
                end
            end

            class FakeTestCase
                class << self
                    attr_accessor :fixture_paths, :file_fixture_path
                    attr_reader :fixture_classes, :fixture_sets

                    def set_fixture_class(classes)
                        @fixture_classes = classes
                    end

                    def fixtures(*sets)
                        @fixture_sets = sets
                    end
                end
            end

            class FakeIntegrationTest < FakeTestCase
            end

            class FakeMigrationPaths
                def initialize(paths)
                    @paths = paths
                end

                def expanded
                    @paths.dup
                end

                def <<(path)
                    @paths << path
                end
            end

            FakeConfig = Struct.new(:paths)
            FakeApplication = Struct.new(:root, :config)

            Dir.mktmpdir("lesli-testing-fixtures") do |directory|
                owner_root = File.join(directory, "owner")
                shared_root = File.join(directory, "shared")
                dummy_root = File.join(directory, "dummy")
                extra_fixtures = File.join(directory, "extra-fixtures")
                extra_migrations = File.join(directory, "extra-migrations")

                [
                    File.join(owner_root, "test", "fixtures", "files"),
                    File.join(owner_root, "db", "migrate"),
                    File.join(shared_root, "test", "fixtures"),
                    File.join(shared_root, "db", "migrate"),
                    File.join(dummy_root, "db", "migrate"),
                    extra_fixtures,
                    extra_migrations
                ].each { |path| FileUtils.mkdir_p(path) }

                module Owner
                    class Engine
                    end
                end
                module Shared
                    class Engine
                    end
                end

                Owner::Engine.define_singleton_method(:root) { owner_root }
                Shared::Engine.define_singleton_method(:root) { shared_root }

                require "lesli_testing/fixtures"

                LesliTesting::Fixtures.install!(
                    profile: "engine",
                    engine_name: "Owner",
                    options: {
                        fixtures: {
                            shared: ["Shared"],
                            shared_paths: [extra_fixtures],
                            sets: [:owner_records],
                            classes: { owner_records: "Owner::Record" }
                        },
                        migrations: {
                            shared: ["Shared"],
                            paths: [extra_migrations]
                        }
                    }
                )

                existing_fixtures = File.join(directory, "existing-fixtures")
                FakeTestCase.fixture_paths = [existing_fixtures]
                ActiveSupport::HOOKS.fetch(:active_support_test_case).call(FakeTestCase)
                ActiveSupport::HOOKS.fetch(:action_dispatch_integration_test).call(FakeIntegrationTest)

                expected_fixture_paths = [
                    File.join(owner_root, "test", "fixtures"),
                    File.join(shared_root, "test", "fixtures"),
                    extra_fixtures,
                    existing_fixtures
                ]
                abort "Wrong fixture paths: #{FakeTestCase.fixture_paths.inspect}" unless FakeTestCase.fixture_paths == expected_fixture_paths
                abort "Integration fixtures missing" unless FakeIntegrationTest.fixture_paths.take(3) == expected_fixture_paths.take(3)
                abort "Wrong file fixture path" unless FakeTestCase.file_fixture_path == File.join(owner_root, "test", "fixtures", "files")
                abort "Fixture sets were not configured" unless FakeTestCase.fixture_sets == [:owner_records]
                abort "Fixture class mapping missing" unless FakeTestCase.fixture_classes[:owner_records] == "Owner::Record"
                abort "ActiveRecord fixtures were not included" unless FakeTestCase < ActiveRecord::TestFixtures

                direct_test_case = Class.new(FakeTestCase)
                direct_test_case.fixture_paths = []
                LesliTesting::Fixtures.load_fixtures_for_engine(
                    Owner::Engine,
                    test_case: direct_test_case
                )
                abort "Direct engine fixture loading failed" unless direct_test_case.fixture_paths.take(3) == expected_fixture_paths.take(3)

                existing_migration = File.join(directory, "existing-migration")
                FileUtils.mkdir_p(existing_migration)
                migration_paths = FakeMigrationPaths.new([existing_migration])
                application = FakeApplication.new(
                    dummy_root,
                    FakeConfig.new({ "db/migrate" => migration_paths })
                )
                ActiveRecord::Migrator.migrations_paths = [existing_migration]

                configured_migrations = LesliTesting::Fixtures.configure_migration_paths(application)
                expected_migrations = [
                    File.join(dummy_root, "db", "migrate"),
                    File.join(owner_root, "db", "migrate"),
                    File.join(shared_root, "db", "migrate"),
                    extra_migrations
                ]

                abort "Wrong migration paths" unless configured_migrations == expected_migrations
                abort "Rails migration paths missing" unless migration_paths.expanded == [existing_migration, *expected_migrations]
                abort "ActiveRecord migration paths missing" unless ActiveRecord::Migrator.migrations_paths == [existing_migration, *expected_migrations]

                Dir.chdir(directory) do
                    ActiveRecord::Migrator.migrations_paths = ["owner/db/migrate"]
                    LesliTesting::Fixtures.configure_migration_paths(application)

                    canonical_paths = ActiveRecord::Migrator.migrations_paths.map do |path|
                        File.expand_path(path)
                    end
                    owner_migrations = File.join(owner_root, "db", "migrate")
                    abort "Equivalent relative migration path was duplicated" unless canonical_paths.count(owner_migrations) == 1
                end
            end
        RUBY

        stdout, stderr, status = Open3.capture3(
            { "COVERAGE" => nil },
            RbConfig.ruby,
            "-I#{LIB_PATH}",
            "-e",
            script,
            chdir: PROJECT_ROOT
        )

        assert status.success?, [stdout, stderr].join("\n")
    end

    def test_app_profile_only_adds_shared_fixtures
        script = <<~'RUBY'
            module ActiveSupport
                HOOKS = {}

                def self.on_load(name, **options, &block)
                    HOOKS[name] = block
                end
            end

            module Lesli
                class Engine
                    def self.root
                        "/shared/lesli"
                    end
                end
            end

            class FakeTestCase
                class << self
                    attr_accessor :fixture_paths, :file_fixture_path
                    attr_reader :fixture_sets

                    def set_fixture_class(classes)
                    end

                    def fixtures(*sets)
                        @fixture_sets = sets
                    end
                end
            end

            require "lesli_testing/fixtures"

            FakeTestCase.fixture_paths = ["/app/test/fixtures"]
            FakeTestCase.file_fixture_path = "/app/test/fixtures/files"

            LesliTesting::Fixtures.install!(
                profile: "app",
                engine_name: "ExampleApp",
                options: {}
            )
            ActiveSupport::HOOKS.fetch(:active_support_test_case).call(FakeTestCase)

            expected_paths = [
                "/app/test/fixtures",
                "/shared/lesli/test/fixtures"
            ]
            abort "App fixture paths were replaced" unless FakeTestCase.fixture_paths == expected_paths
            abort "App file fixtures were replaced" unless FakeTestCase.file_fixture_path == "/app/test/fixtures/files"
            abort "App fixtures were loaded automatically" if FakeTestCase.fixture_sets
        RUBY

        stdout, stderr, status = Open3.capture3(
            { "COVERAGE" => nil },
            RbConfig.ruby,
            "-I#{LIB_PATH}",
            "-e",
            script,
            chdir: PROJECT_ROOT
        )

        assert status.success?, [stdout, stderr].join("\n")
    end
end
