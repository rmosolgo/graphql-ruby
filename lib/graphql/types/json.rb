# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module Types
    # An untyped JSON scalar that maps to Ruby hashes, arrays, strings, integers, floats, booleans and nils.
    # This should be used judiciously because it subverts the GraphQL type system.
    #
    # Use it for fields or arguments as follows:
    #
    #     field :template_parameters, GraphQL::Types::JSON, null: false
    #
    #     argument :template_parameters, GraphQL::Types::JSON, null: false
    #
    class JSON < GraphQL::Schema::Scalar
      description "Represents untyped JSON"

      #: (untyped value, GraphQL::Query::Context _context) -> untyped
      def self.coerce_input(value, _context)
        value
      end

      #: (untyped value, GraphQL::Query::Context _context) -> untyped
      def self.coerce_result(value, _context)
        value
      end
    end
  end
end
