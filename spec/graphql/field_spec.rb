require "spec_helper"

describe GraphQL::Field do
  it "accepts a proc as type" do
    field = GraphQL::Field.define do
      type(-> { DairyProductUnion })
    end

    assert_equal(DairyProductUnion, field.type)
  end

  it "accepts a string as a type" do
    field = GraphQL::Field.define do
      type("DairyProductUnion")
    end

    assert_equal(DairyProductUnion, field.type)
  end

  it "accepts arguments definition" do
    number = GraphQL::Argument.define(name: :number, type: -> { GraphQL::INT_TYPE })
    field = GraphQL::Field.define(type: DairyProductUnion, arguments: [number])
    assert_equal([number], field.arguments)
  end

  describe ".property " do
    let(:field) do
      GraphQL::Field.define do
        name "field_name"
        # satisfies 'can define by config' below
        property :internal_prop
      end
    end

    it "can define by config" do
      assert_equal(field.property, :internal_prop)
    end

    it "has nil property if not defined" do
      no_prop_field = GraphQL::Field.define { }
      assert_equal(no_prop_field.property, nil)
    end

    describe "default resolver" do
      def acts_like_default_resolver(field, old_prop, new_prop)
        object = OpenStruct.new(old_prop => "old value", new_prop => "new value", field.name.to_sym => "unset value")


        old_result = field.resolve(object, nil, nil)
        field.property = new_prop
        new_result = field.resolve(object, nil, nil)
        field.property = nil
        unset_result = field.resolve(object, nil, nil)

        assert_equal(old_result, "old value")
        assert_equal(new_result, "new value")
        assert_equal(unset_result, "unset value")
      end

      it "responds to changes in property" do
        acts_like_default_resolver(field, :internal_prop, :new_prop)
      end

      it "is reassigned if resolve is set to nil" do
        field.resolve = nil
        acts_like_default_resolver(field, :internal_prop, :new_prop)
      end
    end
  end

  describe "#name" do
    it "can't be reassigned" do
      field = GraphQL::Field.define do
        name("something")
      end
      assert_equal "something", field.name
      assert_raises(RuntimeError) { field.name = "somethingelse" }
      assert_equal "something", field.name
    end

    it "must be a string" do
      dummy_query = GraphQL::ObjectType.define do
        name "QueryType"
      end

      invalid_field = GraphQL::Field.new
      invalid_field.type = dummy_query
      invalid_field.name = :symbol_name

      dummy_query.fields["symbol_name"] = invalid_field

      err = assert_raises(GraphQL::Schema::InvalidTypeError) {
        GraphQL::Schema.define(query: dummy_query)
      }
      assert_equal "QueryType is invalid: field :symbol_name name must return String, not Symbol (:symbol_name)", err.message
    end
  end

  describe "#hash_key" do
    let(:source_field) { MilkType.get_field("source") }
    after { source_field.hash_key = :source }

    it "looks up a value with obj[hash_key]" do
      resolved_source = source_field.resolve({source: "Abc", "source" => "Xyz"}, nil, nil)
      assert_equal :source, source_field.hash_key
      assert_equal "Abc", resolved_source
    end

    it "can be reassigned" do
      source_field.hash_key = "source"
      resolved_source = source_field.resolve({source: "Abc", "source" => "Xyz"}, nil, nil)
      assert_equal "source", source_field.hash_key
      assert_equal "Xyz", resolved_source
    end
  end

  describe "#metadata" do
    it "accepts user-defined metadata" do
      similar_cheese_field = CheeseType.get_field("similarCheese")
      assert_equal [:cheeses, :milks], similar_cheese_field.metadata[:joins]
    end
  end

  describe "reusing a GraphQL::Field" do
    let(:schema) {
      int_field = GraphQL::Field.define do
        type types.Int
        argument :value, types.Int
        resolve -> (obj, args, ctx) { args[:value] }
      end

      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :int, int_field
        field :int2, int_field
        field :int3, field: int_field
      end

      GraphQL::Schema.define do
        query(query_type)
      end
    }

    it "can be used in two places" do
      res = schema.execute %|{ int(value: 1) int2(value: 2) int3(value: 3) }|
      assert_equal({ "int" => 1, "int2" => 2, "int3" => 3}, res["data"], "It works in queries")

      res = schema.execute %|{ __type(name: "Query") { fields { name } } }|
      query_field_names = res["data"]["__type"]["fields"].map { |f| f["name"] }
      assert_equal ["int", "int2", "int3"], query_field_names, "It works in introspection"
    end
  end
end
