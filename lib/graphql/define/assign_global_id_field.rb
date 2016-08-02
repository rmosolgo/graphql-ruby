module GraphQL
  module Define
    module AssignGlobalIdField
      def self.call(type_defn, field_name)
        type_defn.name || raise("You must define the type's name before creating a GlobalIdField")
        GraphQL::Define::AssignObjectField.call(type_defn, field_name, field: GraphQL::Relay::GlobalIdField.new(type_defn.name))
      end
    end
  end
end
