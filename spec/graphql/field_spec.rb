# frozen_string_literal: true
require "spec_helper"

# Must be top-level so it can be found by string
FieldSpecReturnType = GraphQL::ObjectType.define do
  name "FieldReturn"
  field :id, types.Int
  field :source, types.String, hash_key: :source
end

describe GraphQL::Field do

  it "accepts a proc as type" do
    field = GraphQL::Field.define do
      type(-> { FieldSpecReturnType })
    end

    assert_equal(FieldSpecReturnType, field.type)
  end

  it "accepts a string as a type" do
    field = GraphQL::Field.define do
      type("FieldSpecReturnType")
    end

    assert_equal(FieldSpecReturnType, field.type)
  end

  it "accepts arguments definition" do
    number = GraphQL::Argument.define(name: :number, type: -> { GraphQL::INT_TYPE })
    field = GraphQL::Field.define(type: FieldSpecReturnType, arguments: [number])
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
    it "must be a string" do
      dummy_query = GraphQL::ObjectType.define do
        name "QueryType"
      end

      invalid_field = GraphQL::Field.new
      invalid_field.type = dummy_query
      invalid_field.name = :symbol_name

      dummy_query.fields["symbol_name"] = invalid_field

      err = assert_raises(GraphQL::Schema::InvalidTypeError) {
        GraphQL::Schema.define(query: dummy_query, raise_definition_error: true)
      }
      assert_equal "QueryType is invalid: field :symbol_name name must return String, not Symbol (:symbol_name)", err.message
    end
  end

  describe "#hash_key" do
    let(:source_field) { FieldSpecReturnType.get_field("source") }
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
      similar_cheese_field = Dummy::CheeseType.get_field("similarCheese")
      assert_equal [:cheeses, :milks], similar_cheese_field.metadata[:joins]
    end
  end

  describe "reusing a GraphQL::Field" do
    let(:schema) {
      int_field = GraphQL::Field.define do
        type types.Int
        argument :value, types.Int
        resolve ->(obj, args, ctx) { args[:value] }
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

  describe "#redefine" do
    it "can add arguments" do
      int_field = GraphQL::Field.define do
        argument :value, types.Int
      end

      int_field_2 = int_field.redefine do
        argument :value_2, types.Int
      end

      assert_equal 1, int_field.arguments.size
      assert_equal 2, int_field_2.arguments.size
    end

    it "rebuilds when the resolve_proc is default NameResolve" do
      int_field = GraphQL::Field.define do
        name "a"
      end

      int_field_2 = int_field.redefine(name: "b")

      object = Struct.new(:a, :b).new(1, 2)

      assert_equal 1, int_field.resolve_proc.call(object, nil, nil)
      assert_equal 2, int_field_2.resolve_proc.call(object, nil, nil)
    end

    it "keeps the same resolve_proc when it is not a NameResolve" do
      int_field = GraphQL::Field.define do
        name "a"
        resolve ->(obj, _, _) { 'GraphQL is Kool' }
      end

      int_field_2 = int_field.redefine(name: "b")

      assert_equal(
        int_field.resolve_proc.call(nil, nil, nil),
        int_field_2.resolve_proc.call(nil, nil, nil)
      )
    end

    it "keeps the same resolve_proc when it is a built in property resolve" do
      int_field = GraphQL::Field.define do
        name "a"
        property :c
      end

      int_field_2 = int_field.redefine(name: "b")

      object = Struct.new(:a, :b, :c).new(1, 2, 3)

      assert_equal 3, int_field.resolve_proc.call(object, nil, nil)
      assert_equal 3, int_field_2.resolve_proc.call(object, nil, nil)
    end

    it "copies metadata, even out-of-bounds assignments" do
      int_field = GraphQL::Field.define do
        metadata(:a, 1)
        argument :value, types.Int
      end
      int_field.metadata[:b] = 2

      int_field_2 = int_field.redefine do
        metadata(:c, 3)
        argument :value_2, types.Int
      end

      assert_equal({a: 1, b: 2}, int_field.metadata)
      assert_equal({a: 1, b: 2, c: 3}, int_field_2.metadata)
    end
  end

  describe "#resolve_proc" do
    it "ensures the definition was called" do
      class SimpleResolver
        def self.call(*args)
          :whatever
        end
      end

      field_with_proc = GraphQL::Field.define do
        resolve ->(o, a, c) { :whatever }
      end

      field_with_class = GraphQL::Field.define do
        resolve SimpleResolver
      end

      assert_respond_to field_with_proc.resolve_proc, :call
      assert_respond_to field_with_class.resolve_proc, :call
    end
  end
end
