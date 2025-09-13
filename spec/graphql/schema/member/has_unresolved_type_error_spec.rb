# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasUnresolvedTypeError do
  it "adds error classes to interfaces and unions" do
    assert_equal Jazz::NamedEntity::UnresolvedTypeError.superclass, GraphQL::UnresolvedTypeError
    assert_equal Jazz::PerformingAct::UnresolvedTypeError.superclass, GraphQL::UnresolvedTypeError
    assert Jazz::NamedEntity.const_defined?(:UnresolvedTypeError, false)
    assert Jazz::PerformingAct.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::Musician.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::Family.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::Key.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::InspectableInput.const_defined?(:UnresolvedTypeError, false)
  end

  it "doesn't add an error class to anonymous classes" do
    anon_int = Module.new do
      include GraphQL::Schema::Interface
      graphql_name "AnonInt"
    end

    obj_t = Class.new(GraphQL::Schema::Object) do
      graphql_name "Obj"
      implements anon_int
    end

    anon_union = Class.new(GraphQL::Schema::Union) do
      graphql_name "AnonUnion"
      possible_types(obj_t)
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :anon_union, anon_union, fallback_value: 1
      field :anon_int, anon_int, fallback_value: 1
    end

    schema = Class.new(GraphQL::Schema) do
      query(query_type)
      use GraphQL::Schema::Visibility
      def self.resolve_type(abs_t, obj, ctx)
        ctx.schema.query
      end
    end

    err = assert_raises do
      schema.execute("{ anonUnion { __typename } }")
    end
    assert_equal "GraphQL::UnresolvedTypeError", err.class.name

    err = assert_raises do
      schema.execute("{ anonInt { __typename } }")
    end
    assert_equal "GraphQL::UnresolvedTypeError", err.class.name
    assert_equal <<~ERR.chomp, err.message
    The value from "anonInt" on "Query" could not be resolved to "AnonInt". (Received: `Query`, Expected: [Obj]) Make sure you have defined a `resolve_type` method on your schema and that value `1` gets resolved to a valid type. You may need to add your type to `orphan_types` if it implements an interface but isn\'t a return type of any other field.

    `AnonInt.orphan_types`: []
    `Schema.visibility.all_interface_type_memberships[AnonInt]` (1):
        - `Obj` | Object? true | referenced? true | visible? true | membership_visible? [true]
    ERR
  end
end
