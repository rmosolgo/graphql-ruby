# A wrapper to create `__type(name: )` dynamically.
class GraphQL::Introspection::TypeByNameField
  DEFINITION = Proc.new { |f, type, field, arg, type_hash|
    f.name("__type")
    f.description("A type in the GraphQL system")
    f.arguments({name: arg.build(type: !type.String)})
    f.type(!GraphQL::Introspection::TypeType)
    f.resolve -> (o, args, c) { type_hash[args["name"]] }
  }

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
