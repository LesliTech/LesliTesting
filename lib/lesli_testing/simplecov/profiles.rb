SimpleCov.profiles.define "lesli_rails_app" do
    load_profile "rails"
    track_files "{app,lib,engines,gems}/**/*.rb"
end

SimpleCov.profiles.define "lesli_rails_engine" do
    load_profile "rails"
      add_filter %r{^/test/}
end

SimpleCov.profiles.define "lesli_rails_gem" do
    load_profile "rails"
end
