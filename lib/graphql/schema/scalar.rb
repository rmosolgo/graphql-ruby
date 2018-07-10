# frozen_string_literal: true
module GraphQL
  class Schema
    class Scalar < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        extend Forwardable
        def_delegators :graphql_definition, :coerce_isolated_input, :coerce_isolated_result

        def coerce_input(val, ctx)
          val
        end

        def coerce_result(val, ctx)
          val
        end

        def to_graphql
          type_defn = GraphQL::ScalarType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.coerce_result = method(:coerce_result)
          type_defn.coerce_input = method(:coerce_input)
          type_defn.metadata[:type_class] = self
          type_defn.default_scalar = default_scalar
          type_defn
        end

        def kind
          GraphQL::TypeKinds::SCALAR
        end

        def default_scalar(is_default = nil)
          if !is_default.nil?
            @default_scalar = is_default
          end
          @default_scalar
        end
      end
    end
  end
end
