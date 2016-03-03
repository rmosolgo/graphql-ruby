require "spec_helper"

describe GraphQL::Schema::TypeValidator do
  let(:base_type_defn) {
    {
      name: "InvalidType",
      description: "...",
      deprecation_reason: nil,
      kind: GraphQL::TypeKinds::OBJECT,
      interfaces: [],
      fields: {},
    }
  }
  let(:object) {
    o = OpenStruct.new(type_defn)
    def o.to_s; "InvalidType"; end
    o
  }
  let(:validator) { GraphQL::Schema::TypeValidator.new }
  let(:errors) { e = []; validator.validate(object, e); e;}
  describe "when name isnt defined" do
    let(:type_defn) { base_type_defn.delete_if {|k,v| k == :name }}
    it "requires name" do
      assert_equal(
        ["InvalidType must respond to #name() to be a Type"],
        errors
      )
    end
  end

  describe "when a method returns nil" do
    let(:type_defn) { base_type_defn.merge(interfaces: nil)}
    it "requires name" do
      assert_equal(
        ["InvalidType must return a value for #interfaces() to be a OBJECT"],
        errors
      )
    end
  end

  describe "when a field name isnt a string" do
    let(:type_defn) { base_type_defn.merge(fields: {symbol_field: (GraphQL::Field.new {|f|}) }) }
    it "requires string names" do
      assert_equal(
        ["InvalidType.fields keys must be Strings, but some aren't: symbol_field"],
        errors
      )
    end
  end

  describe "when a Union isnt valid" do
    let(:object) {
      union_types = types
      GraphQL::UnionType.define do
        name "Something"
        description "some union"
        possible_types union_types
      end
    }
    let(:errors) { e = []; GraphQL::Schema::TypeValidator.new.validate(object, e); e;}

    describe "when non-object types" do
      let(:types) { [DairyProductInputType] }
      it "must be must be only object types" do
        expected = [
          "Something.possible_types must be objects, but some aren't: DairyProductInput"
        ]
        assert_equal(expected, errors)
      end
    end
    describe "when no types" do
      let(:types) { [] }
      it "must have a type" do
        expected = [
          "Union Something must be defined with 1 or more types, not 0!"
        ]
        assert_equal(expected, errors)
      end
    end
  end
end
