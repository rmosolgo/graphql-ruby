# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::DocumentFromSchemaDefinition do
  let(:idl) {<<-schema
    schema {
      query: Query
      mutation: Mutation
    }

    type Query {
      annotatedObject: AnnotatedObject
    }

    type Mutation {
      doThing(input: InputType): Foo
    }

    # Union description
    union AnnotatedUnion @onUnion = A | B

    type Foo implements Bar {
      one: Type
      two(argument: InputType!): Type
      three(argument: InputType, other: String): Int
      four(argument: String = "string"): String
      five(argument: [String] = ["string", "string"]): String
      six(argument: InputType = {key: "value"}): Type
      seven(argument: String = null): Type
    }

    type Type {
      aScalar: CustomScalar
    }

    # Scalar description
    scalar CustomScalar

    type AnnotatedObject @onObject(arg: "value") {
      annotatedField(arg: String = "default" @onArg): Type @onField
    }

    interface Bar {
      one: Type
      four(argument: String = "string"): String
    }

    # Enum description
    enum Site {
      # Enum value description
      DESKTOP
      MOBILE
    }

    interface AnnotatedInterface @onInterface {
      annotatedField(arg: Type @onArg): Type @onField
    }

    union Feed = Story | Article | Advert

    # Input description
    input InputType {
      key: String!
      answer: Int = 42
    }

    union AnnotatedUnion @onUnion = A | B

    scalar CustomScalar

    # Directive description
    directive @skip(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

    scalar AnnotatedScalar @onScalar

    enum Site {
      DESKTOP
      MOBILE
    }

    enum AnnotatedEnum @onEnum {
      ANNOTATED_VALUE @onEnumValue
      OTHER_VALUE
    }

    input InputType {
      key: String!
      answer: Int = 42
    }

    input AnnotatedInput @onInputObjectType {
      annotatedField: Type @onField
    }

    directive @skip(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

    directive @include(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT
  schema
  }

  let(:schema) {
    GraphQL::Schema::BuildFromDefinition.from_definition(
      idl,
      default_resolve: ->(_, _, _) {}
    )
  }

  let(:subject) { GraphQL::Language::DocumentFromSchemaDefinition }

  describe "#document" do
    it "returns the document AST from the given schema" do
      document = subject.new(schema).document

      assert_equal "", document.to_query_string
    end
  end
end
