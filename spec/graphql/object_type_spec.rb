# frozen_string_literal: true
require "spec_helper"

describe GraphQL::ObjectType do
  let(:type) { Dummy::CheeseType }

  it "has a name" do
    assert_equal("Cheese", type.name)
    type.name = "Fromage"
    assert_equal("Fromage", type.name)
    type.name = "Cheese"
  end

  it "has a description" do
    assert_equal(22, type.description.length)
  end

  it "may have interfaces" do
    assert_equal([Dummy::EdibleInterface, Dummy::AnimalProductInterface, Dummy::LocalProductInterface], type.interfaces)
  end

  it "accepts fields definition" do
    last_produced_dairy = GraphQL::Field.define(name: :last_produced_dairy, type: Dummy::DairyProductUnion)
    cow_type = GraphQL::ObjectType.define(name: "Cow", fields: [last_produced_dairy])
    assert_equal([last_produced_dairy], cow_type.fields)
  end

  describe '#get_field' do
    it "exposes fields" do
      field = type.get_field("id")
      assert_equal(GraphQL::TypeKinds::NON_NULL, field.type.kind)
      assert_equal(GraphQL::TypeKinds::SCALAR, field.type.of_type.kind)
    end

    it "exposes defined field property" do
      field_without_prop = Dummy::CheeseType.get_field("flavor")
      field_with_prop = Dummy::CheeseType.get_field("fatContent")
      assert_equal(field_without_prop.property, nil)
      assert_equal(field_with_prop.property, :fat_content)
    end

    it "looks up from interfaces" do
      field_from_self = Dummy::CheeseType.get_field("fatContent")
      field_from_iface = Dummy::MilkType.get_field("fatContent")
      assert_equal(field_from_self.property, :fat_content)
      assert_equal(field_from_iface.property, nil)
    end
  end

  describe "#dup" do
    it "copies fields and interfaces without altering the original" do
      type.interfaces # load the internal cache
      type_2 = type.dup

      # IRL, use `+=`, not this
      # (this tests the internal cache)
      type_2.interfaces << type

      type_2.fields["nonsense"] = GraphQL::Field.define(name: "nonsense", type: type)

      assert_equal 3, type.interfaces.size
      assert_equal 4, type_2.interfaces.size
      assert_equal 8, type.fields.size
      assert_equal 9, type_2.fields.size
    end
  end
end
