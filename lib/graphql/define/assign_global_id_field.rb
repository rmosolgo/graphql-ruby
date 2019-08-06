# frozen_string_literal: true
module GraphQL
  module Define
    module AssignGlobalIdField
      def self.call(type_defn, field_name)
        resolve = GraphQL::Relay::GlobalIdResolve.new(type: type_defn)
        GraphQL::Define::AssignObjectField.call(type_defn, field_name, type: GraphQL::ID_TYPE.to_non_null_type, resolve: resolve)
      end
    end
  end
end
