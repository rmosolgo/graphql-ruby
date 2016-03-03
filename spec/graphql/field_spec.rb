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
      assert_raises { field.name = "somethingelse" }
      assert_equal "something", field.name
    end
  end
end
