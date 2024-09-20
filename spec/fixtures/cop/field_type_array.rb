class Types::FooType < Types::BaseObject
  field :other, String
  field :bar, [String], null: false do
    argument :baz, String
  end
end
