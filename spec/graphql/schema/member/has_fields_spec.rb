# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasFields do
  module SuperTest
    class BaseObject < GraphQL::Schema::Object
    end

    module BaseInterface
      include GraphQL::Schema::Interface
    end

    module InterfaceWithFloatField
      include BaseInterface
      field :float, Float, null: false
      def float
        # This should call the default implementation
        super * 0.5
      end
    end

    module SubInterfaceWithFloatField
      include InterfaceWithFloatField
      def float
        # This should call `InterfaceWithFloatField#float`
        super * 0.1
      end
    end

    class ObjectWithFloatField < BaseObject
      implements InterfaceWithFloatField
    end

    class ObjectWithSubFloatField < BaseObject
      implements SubInterfaceWithFloatField
    end

    module InterfaceWithStringField
      include BaseInterface
      field :string, String, null: false
      def string
        # Return a literal value to ensure this method was called
        "here's a string"
      end
    end

    class ObjectWithStringField < BaseObject
      implements InterfaceWithStringField
      def string
        # This should call to `InterfaceWithStringField#string`
        super.upcase
      end
    end

    class SubObjectWithStringField < ObjectWithStringField
      def string
        # This should call to `ObjectWithStringField#string`
        super.reverse
      end
    end

    class SubSubObjectWithStringField < SubObjectWithStringField
      field :string, String, null: false
    end

    class Query < BaseObject
      field :int, Integer, null: false
      def int
        # This should call default resolution
        super * 2
      end

      field :string1, ObjectWithStringField, null: false, method: :object
      field :string2, SubObjectWithStringField, null: false, method: :object
      field :string3, SubSubObjectWithStringField, null: false, method: :object
      field :float1, ObjectWithFloatField, null: false, method: :object
      field :float2, ObjectWithSubFloatField, null: false, method: :object
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
  end

  describe "Calling super in field methods" do
    # Test that calling `super` in field methods "works", which means:
    # - If there is a super method in the user-created hierarchy (either a class or module), it is called
    #   This is tested by putting random transformations in method bodies,
    #   then asserting that they are called.
    # - If there's no user-defined super method, it calls the built-in default behavior
    #   This is tested by putting values in the `root_value` hash.
    #   The default behavior is to fetch hash values by key, so we assert that
    #   those values are subject to the specified transformations.

    describe "Object methods" do
      it "may call super to default implementation" do
        res = SuperTest::Schema.execute("{ int }", root_value: { int: 4 })
        assert_equal 8, res["data"]["int"]
      end

      it "may call super to interface method" do
        res = SuperTest::Schema.execute(" { string1 { string } }", root_value: {})
        assert_equal "HERE'S A STRING", res["data"]["string1"]["string"]
      end

      it "may call super to superclass method" do
        res = SuperTest::Schema.execute(" { string2 { string } }", root_value: {})
        assert_equal "GNIRTS A S'EREH", res["data"]["string2"]["string"]
      end

      it "can get a super method from a newly-added field" do
        res = SuperTest::Schema.execute(" { string3 { string } }", root_value: {})
        assert_equal "GNIRTS A S'EREH", res["data"]["string3"]["string"]
      end
    end

    describe "Interface methods" do
      it "may call super to interface method" do
        res = SuperTest::Schema.execute(" { float1 { float } }", root_value: { float: 6.0 })
        assert_equal 3.0, res["data"]["float1"]["float"]
      end

      it "may call super to superclass method" do
        res = SuperTest::Schema.execute(" { float2 { float } }", root_value: { float: 6.0 })
        assert_in_delta 0.001, 0.3, res["data"]["float2"]["float"]
      end
    end
  end
end
