# frozen_string_literal: true
module GraphQL
  class Scalar < GraphQL::SchemaMember
    class << self
      def coerce_input(val, ctx)
        raise NotImplementedError, "#{self.name}.coerce_input(val, ctx) must prepare GraphQL input (#{val.inspect}) for Ruby processing"
      end

      def coerce_result(val, ctx)
        raise NotImplementedError, "#{self.name}.coerce_result(val, ctx) must prepare Ruby value (#{val.inspect}) for GraphQL response"
      end

      def to_graphql
        type_defn = GraphQL::ScalarType.new
        type_defn.name = graphql_name
        type_defn.description = description
        type_defn.coerce_result = method(:coerce_result)
        type_defn.coerce_input = method(:coerce_input)
        type_defn
      end
    end
  end
end
