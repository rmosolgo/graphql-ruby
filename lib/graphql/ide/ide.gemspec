$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "graphql/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "graphql_ide"
  spec.version     = GraphQL::VERSION
  spec.authors     = ["Robert Mosolgo", "Damon Aw"]
  spec.email       = ["rdmosolgo@gmail.com", "daemonsy@gmail.com"]

  spec.homepage    = "https://github.com/rmosolgo/graphql-ruby"
  spec.summary     = "A mountable endpoint that exposes for Rails"
  spec.description = "Rack endpoint / Rails engine that exposes GraphiQL and GraphQL Playground"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile"]

  spec.add_runtime_dependency "railties"
end
