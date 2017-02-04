require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Generate a `Relay::Mutation` by name.
    #
    # ```
    # rails g graphql:mutation CreatePostMutation ... ?
    # ```
    #
    # What other options should be supported?
    class MutationGenerator < BaseGenerator
    end
  end
end
