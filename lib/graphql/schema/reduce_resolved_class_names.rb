module GraphQL
  class Schema
    module ReduceResolvedClassNames
      class ResolvedClassNameReducer < BaseReducer
        def reduce_value(type)
          type.resolved_class_name || type.name
        end

        protected

        def should_visit?(type, type_hash)
          type_hash.fetch(type.name, nil).equal?(nil) && type.is_a?(GraphQL::ObjectType)
        end
      end

      # @param types [Array<GraphQL::BaseType>] members of a schema to crawl for all member types
      # @return [GraphQL::Schema::TypeMap] `{name => Type}` pairs derived from `types`
      def self.reduce(types)
        type_map = GraphQL::Schema::TypeMap.new
        reducer = ResolvedClassNameReducer.new
        types.each do |type|
          reducer.reduce_type(type, type_map, type.name)
        end
        type_map
      end
    end
  end
end
