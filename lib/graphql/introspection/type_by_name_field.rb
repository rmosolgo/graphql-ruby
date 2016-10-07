module GraphQL
  module Introspection
    # A wrapper to create `__type(name: )` dynamically.
    class TypeByNameField
      def self.create(schema)
        GraphQL::Field.define do
          name("__type")
          description("A type in the GraphQL system")
          type(GraphQL::Introspection::TypeType)
          argument :name, !types.String
          resolve ->(o, args, c) {
            type_defn = schema.types.fetch(args["name"], nil)
            if type_defn && schema.visible_type?(type_defn)
              type_defn
            else
              nil
            end
          }
        end
      end
    end
  end
end
