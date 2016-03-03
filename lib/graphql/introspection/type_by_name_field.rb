module GraphQL
  module Introspection
    # A wrapper to create `__type(name: )` dynamically.
    class TypeByNameField
      def self.create(type_hash)
        GraphQL::Field.define do
          name("__type")
          description("A type in the GraphQL system")
          type(!GraphQL::Introspection::TypeType)
          argument :name, !types.String
          resolve -> (o, args, c) { type_hash[args["name"]] }
        end
      end
    end
  end
end
