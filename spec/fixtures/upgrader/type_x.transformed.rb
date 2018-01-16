# frozen_string_literal: true

module Platform
  module Objects
    class X < Platform::Objects::Base
      model_name "X"
      description "An x on a y."
      visibility :internal
      minimum_accepted_scopes ["z"]

      global_id_field :id
      implements GraphQL::Relay::Node.interface

      field :f1, Objects::O1, "The x being y.", null: false
      field :f2, Enums::E1, "x for the y.", method: :field_2, null: false
      field :f3, Enums::E2, "x for y.", null: true
      field :details, String, "Details.", null: true

      field :f4, Objects::O2, "x as a y inside the z.", null: false

      def f4
        Class1.new(
          a: Class2.new(
            b: @object.b_1,
            c: @object.c_1
          ),
          d: Class3.new(
            b: @object.b_2,
            c: @object.c_3,
          )
        )
      end

      field :f5, String, visibility: :custom_value, method: :custom_property, description: "The thing", null: false

      field :f6, String, visibility: :custom_value, method: :custom_property, description: "The thing", null: false
    end
  end
end
