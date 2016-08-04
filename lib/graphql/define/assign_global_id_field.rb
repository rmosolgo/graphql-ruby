module GraphQL
  module Define
    module AssignGlobalIdField
      def self.call(type_defn, field_name)
        type_defn.name || raise("You must define the type's name before creating a GlobalIdField")
        resolve = GraphQL::Relay::GlobalIdResolve.new(type_name: type_defn.name, property: field_name)
        GraphQL::Define::AssignObjectField.call(type_defn, field_name, type: GraphQL::ID_TYPE.to_non_null_type, resolve: resolve)
      end
    end
  end
end
