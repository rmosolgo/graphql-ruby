# frozen_string_literal: true
# typed: strict
module GraphQL
  module Types
    class Boolean < GraphQL::Schema::Scalar
      description "Represents `true` or `false` values."

      #: (untyped value, GraphQL::Query::Context _ctx) -> bool?
      def self.coerce_input(value, _ctx)
        (value == true || value == false) ? value : nil
      end

      #: (untyped value, GraphQL::Query::Context _ctx) -> bool
      def self.coerce_result(value, _ctx)
        !!value
      end

      default_scalar true
    end
  end
end
