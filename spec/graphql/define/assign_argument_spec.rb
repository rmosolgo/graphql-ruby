require "spec_helper"

describe GraphQL::Define::AssignArgument do
  it "it accepts default_value" do
    query_type = GraphQL::ObjectType.define do
      name "Query"
      field :a, types.String do
        argument :a, types.String, default_value: "Default"
      end
    end

    arg = query_type.fields['a'].arguments['a']
    assert_equal "Default", arg.default_value
    assert arg.default_value?
  end

  it "default_value is optional" do
    query_type = GraphQL::ObjectType.define do
      name "Query"
      field :a, types.String do
        argument :a, types.String
      end
    end

    arg = query_type.fields['a'].arguments['a']
    assert arg.default_value.nil?
    assert !arg.default_value?
  end

  it "default_value can be explicitly set to nil" do
    query_type = GraphQL::ObjectType.define do
      name "Query"
      field :a, types.String do
        argument :a, types.String, default_value: nil
      end
    end

    arg = query_type.fields['a'].arguments['a']
    assert arg.default_value.nil?
    assert arg.default_value?
  end

  it "passing unknown keyword arguments will raise" do
    err = assert_raises ArgumentError do
      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :a, types.String do
          argument :a, types.String, blah: nil
        end
      end
      assert query_type.fields['a'].arguments
    end

    assert_equal 'unknown keyword: blah', err.message

    err = assert_raises ArgumentError do
      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :a, types.String do
          argument :a, types.String, blah: nil, blah2: nil
        end
      end
      assert query_type.fields['a'].arguments
    end

    assert_equal 'unknown keywords: blah, blah2', err.message
  end
end
