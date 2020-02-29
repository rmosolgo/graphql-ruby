# frozen_string_literal: true
require "spec_helper"

describe GraphQL::ObjectType do
  let(:type) { Dummy::Cheese.graphql_definition }

  it "doesn't allow invalid name" do
    exception = assert_raises(GraphQL::InvalidNameError) {
      InvalidNameObject = GraphQL::ObjectType.define do
        name "Three Word Query"

        field :id, !types.Int, "id field"
      end

      # Force evaluation
      InvalidNameObject.name
    }
    assert_equal("Names must match /^[_a-zA-Z][_a-zA-Z0-9]*$/ but 'Three Word Query' does not", exception.message)
  end

  it "has a name" do
    assert_equal("Cheese", type.name)
    type.name = "Fromage"
    assert_equal("Fromage", type.name)
    type.name = "Cheese"
  end

  it "has a description" do
    assert_equal(22, type.description.length)
  end

  describe "interfaces" do
    it "may have interfaces" do
      assert_equal([
        Dummy::Edible.graphql_definition,
        Dummy::EdibleAsMilk.graphql_definition,
        Dummy::AnimalProduct.graphql_definition,
        Dummy::LocalProduct.graphql_definition
      ], type.interfaces)
    end

    it "raises if the interfaces arent an array" do
      type = GraphQL::ObjectType.define do
        name "InvalidInterfaces"
        interfaces(55)
      end

      assert_raises(ArgumentError) { type.name }
    end

    it "doesnt convolute field names that differ with underscore" do
      interface = Module.new do
        include GraphQL::Schema::Interface
        graphql_name 'TestInterface'
        description 'Requires an id'

        field :id, GraphQL::ID_TYPE, null: false
      end

      object = Class.new(GraphQL::Schema::Object) do
        graphql_name 'TestObject'
        implements interface
        global_id_field :id

        # When the validation for `id` is run for `_id`, it will fail because
        # GraphQL::STRING_TYPE cannot be transformed into a GraphQL::ID_TYPE
        field :_id, String, description: 'database id', null: true
      end

      assert_equal nil, GraphQL::Schema::Validation.validate(object.to_graphql)
    end
  end

  it "accepts fields definition" do
    last_produced_dairy = GraphQL::Field.define(name: :last_produced_dairy, type: Dummy::DairyProduct)
    cow_type = GraphQL::ObjectType.define(name: "Cow", fields: [last_produced_dairy])
    assert_equal([last_produced_dairy], cow_type.fields)
  end

  describe "#implements" do
    it "adds an interface" do
      type = GraphQL::ObjectType.define do
        name 'Hello'
        implements Dummy::Edible
        implements Dummy::AnimalProduct

        field :hello, types.String
      end

      assert_equal([Dummy::Edible.graphql_definition, Dummy::AnimalProduct.graphql_definition], type.interfaces)
    end

    it "adds many interfaces" do
      type = GraphQL::ObjectType.define do
        name 'Hello'
        implements Dummy::Edible, Dummy::AnimalProduct

        field :hello, types.String
      end

      assert_equal([Dummy::Edible.graphql_definition, Dummy::AnimalProduct.graphql_definition], type.interfaces)
    end

    it "preserves existing interfaces and appends a new one" do
      type = GraphQL::ObjectType.define do
        name 'Hello'
        interfaces [Dummy::Edible]
        implements Dummy::AnimalProduct

        field :hello, types.String
      end

      assert_equal([Dummy::Edible.graphql_definition, Dummy::AnimalProduct.graphql_definition], type.interfaces)
    end

    it "can be used to inherit fields from the interface" do
      type_1 = GraphQL::ObjectType.define do
        name 'Hello'
        implements Dummy::Edible
        implements Dummy::AnimalProduct
      end

      type_2 = GraphQL::ObjectType.define do
        name 'Hello'
        implements Dummy::Edible
        implements Dummy::AnimalProduct, inherit: true
      end

      type_3 = GraphQL::ObjectType.define do
        name 'Hello'
        implements Dummy::Edible, Dummy::AnimalProduct, inherit: true
      end

      assert_equal [], type_1.all_fields.map(&:name)
      assert_equal ["source"], type_2.all_fields.map(&:name)
      assert_equal ["fatContent", "origin", "selfAsEdible", "source"], type_3.all_fields.map(&:name)
    end
  end

  describe '#get_field' do
    it "exposes fields" do
      field = type.get_field("id")
      assert_equal(GraphQL::TypeKinds::NON_NULL, field.type.kind)
      assert_equal(GraphQL::TypeKinds::SCALAR, field.type.of_type.kind)
    end

    it "exposes defined field property" do
      field_without_prop = Dummy::Cheese.graphql_definition.get_field("flavor")
      field_with_prop = Dummy::Cheese.graphql_definition.get_field("fatContent")
      assert_equal(field_without_prop.property, nil)
      # This used to lookup `:fat_content`, but not since migrating to class-based
      assert_equal(field_with_prop.property, nil)
    end

    it "looks up from interfaces" do
      field_from_self = Dummy::Cheese.graphql_definition.get_field("fatContent")
      field_from_iface = Dummy::Milk.graphql_definition.get_field("fatContent")
      # This used to lookup `:fat_content`, but not since migrating to class-based
      assert_equal(field_from_self.property, nil)
      assert_equal(field_from_iface.property, nil)
    end
  end

  describe "#dup" do
    it "copies fields and interfaces without altering the original" do
      type.interfaces # load the internal cache
      assert_equal 4, type.interfaces.size
      assert_equal 9, type.fields.size

      type_2 = type.dup

      # IRL, use `+=`, not this
      # (this tests the internal cache)
      type_2.interfaces << type

      type_2.fields["nonsense"] = GraphQL::Field.define(name: "nonsense", type: type)

      assert_equal 4, type.interfaces.size
      assert_equal 4, type_2.interfaces.size
      assert_equal 9, type.fields.size
      assert_equal 10, type_2.fields.size
    end
  end
end
