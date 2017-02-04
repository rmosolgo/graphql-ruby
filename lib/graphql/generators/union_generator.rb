require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Generate a union type by name
    # with the specified member types.
    #
    # ```
    # rails g graphql:union SearchResultType ImageType AudioType
    # ```
    class UnionGenerator < BaseGenerator
    end
  end
end
