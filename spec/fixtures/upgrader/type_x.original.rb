# frozen_string_literal: true

module Platform
  module Objects
    X = define_active_record_type(-> { ::X }) do
      name "X"
      description "An x on a y."
      visibility :internal
      minimum_accepted_scopes ["z"]

      global_id_field :id
      interfaces [GraphQL::Relay::Node.interface]

      field :f1, !Objects::O1, "The x being y."
      field :f2, !Enums::E1, "x for the y.", property: :field_2
      field :f3, Enums::E2, "x for y."
      field :details, types.String, "Details."

      field :f4, !Objects::O2, "x as a y inside the z." do
        resolve ->(obj_x, arguments, context) do
          Class1.new(
            a: Class2.new(
              b: obj_x.b_1,
              c: obj_x.c_1
            ),
            d: Class3.new(
              b: obj_x.b_2,
              c: obj_x.c_3,
            )
          )
        end
      end
    end
  end
end
