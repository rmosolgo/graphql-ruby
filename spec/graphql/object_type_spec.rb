require "spec_helper"

describe GraphQL::ObjectType do
  let(:type) { CheeseType }

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
    assert_equal([EdibleInterface, AnimalProductInterface], type.interfaces)
  end

  describe '#get_field ' do
    it "exposes fields" do
      field = type.get_field("id")
      assert_equal(GraphQL::TypeKinds::NON_NULL, field.type.kind)
      assert_equal(GraphQL::TypeKinds::SCALAR, field.type.of_type.kind)
    end

    it "exposes defined field property" do
      field_without_prop = CheeseType.get_field("flavor")
      field_with_prop = CheeseType.get_field("fatContent")
      assert_equal(field_without_prop.property, nil)
      assert_equal(field_with_prop.property, :fat_content)
    end

    it "looks up from interfaces" do
      field_from_self = CheeseType.get_field("fatContent")
      field_from_iface = MilkType.get_field("fatContent")
      assert_equal(field_from_self.property, :fat_content)
      assert_equal(field_from_iface.property, nil)
    end
  end
end
