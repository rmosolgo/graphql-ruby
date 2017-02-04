require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Generate an interface type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:interface NamedEntityType name:String!
    # ```
    class InterfaceGenerator < BaseGenerator
    end
  end
end
