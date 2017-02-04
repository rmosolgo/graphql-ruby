require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Generate a resolve function for a field.
    #
    # ```
    # rails g graphql:resolver PostAuthorResolver
    # ```
    class ResolverGenerator < BaseGenerator
    end
  end
end
