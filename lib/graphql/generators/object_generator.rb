require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Generate an object type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:object PostType name:String!
    # ```
    #
    # Support an option for adding the Node interface,
    # eg `--node` (?).
    class ObjectGenerator < BaseGenerator
    end
  end
end
