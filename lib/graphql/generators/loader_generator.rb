require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Generate a batch loader by name.
    #
    # ```
    # rails g graphql:loader RecordLoader
    # ```
    #
    # Should we have a loader for the
    # nearly-universal foreign key loader?
    class LoaderGenerator < BaseGenerator
    end
  end
end
