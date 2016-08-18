module GraphQL
  class Schema
    module ReduceTypes
      class TypeReducer < BaseReducer
        def reduce_value(type)
          type
        end

        protected

        def should_visit?(type, type_hash)
          !type_hash.fetch(type.name, nil).equal?(type)
        end
      end

      # @param types [Array<GraphQL::BaseType>] members of a schema to crawl for all member types
      # @return [GraphQL::Schema::TypeMap] `{name => Type}` pairs derived from `types`
      def self.reduce(types)
        type_map = GraphQL::Schema::TypeMap.new
        reducer = TypeReducer.new
        types.each do |type|
          reducer.reduce_type(type, type_map, type.name)
        end
        type_map
      end
    end
  end
end
