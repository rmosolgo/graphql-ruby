# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::ArgumentLiteralsAreCompatible do
  include StaticValidationHelpers
  include ErrorBubblingHelpers

  let(:query_string) {%|
    query getCheese {
      stringCheese: cheese(id: "aasdlkfj") { ...cheeseFields }
      cheese(id: 1) { source @skip(if: "whatever") }
      yakSource: searchDairy(product: [{source: COW, fatContent: 1.1}]) { __typename }
      badSource: searchDairy(product: {source: 1.1}) { __typename }
      missingSource: searchDairy(product: [{fatContent: 1.1}]) { __typename }
      listCoerce: cheese(id: 1) { similarCheese(source: YAK) { __typename } }
      missingInputField: searchDairy(product: [{source: YAK, wacky: 1}]) { __typename }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: 4.5) { __typename }
    }
  |}

  describe "with error bubbling disabled" do
    it "finds undefined or missing-required arguments to fields and directives" do
      without_error_bubbling(schema) do
        # `wacky` above is handled by ArgumentsAreDefined, missingSource is handled by RequiredInputObjectAttributesArePresent
        # so only 4 are tested below
        assert_equal(6, errors.length)

        query_root_error = {
          "message"=>"Argument 'id' on Field 'stringCheese' has an invalid value. Expected type 'Int!'.",
          "locations"=>[{"line"=>3, "column"=>7}],
          "path"=>["query getCheese", "stringCheese", "id"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"id"},
        }
        assert_includes(errors, query_root_error)

        directive_error = {
          "message"=>"Argument 'if' on Directive 'skip' has an invalid value. Expected type 'Boolean!'.",
          "locations"=>[{"line"=>4, "column"=>30}],
          "path"=>["query getCheese", "cheese", "source", "if"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Directive", "argumentName"=>"if"},
        }
        assert_includes(errors, directive_error)

        input_object_field_error = {
          "message"=>"Argument 'source' on InputObject 'DairyProductInput' has an invalid value. Expected type 'DairyAnimal!'.",
          "locations"=>[{"line"=>6, "column"=>39}],
          "path"=>["query getCheese", "badSource", "product", 0, "source"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"InputObject", "argumentName"=>"source"},
        }
        assert_includes(errors, input_object_field_error)

        fragment_error = {
          "message"=>"Argument 'source' on Field 'similarCheese' has an invalid value. Expected type '[DairyAnimal!]!'.",
          "locations"=>[{"line"=>13, "column"=>7}],
          "path"=>["fragment cheeseFields", "similarCheese", "source"],
          "extensions"=> {"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"source"}
        }
        assert_includes(errors, fragment_error)
      end
    end
    it 'works with error bubbling enabled' do
      with_error_bubbling(schema) do
        assert_equal(9, errors.length)

        query_root_error = {
          "message"=>"Argument 'id' on Field 'stringCheese' has an invalid value. Expected type 'Int!'.",
          "locations"=>[{"line"=>3, "column"=>7}],
          "path"=>["query getCheese", "stringCheese", "id"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"id"},
        }
        assert_includes(errors, query_root_error)

        directive_error = {
          "message"=>"Argument 'if' on Directive 'skip' has an invalid value. Expected type 'Boolean!'.",
          "locations"=>[{"line"=>4, "column"=>30}],
          "path"=>["query getCheese", "cheese", "source", "if"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Directive", "argumentName"=>"if"},
        }
        assert_includes(errors, directive_error)

        input_object_error = {
          "message"=>"Argument 'product' on Field 'badSource' has an invalid value. Expected type '[DairyProductInput]'.",
          "locations"=>[{"line"=>6, "column"=>7}],
          "path"=>["query getCheese", "badSource", "product"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"product"},
        }
        assert_includes(errors, input_object_error)

        input_object_field_error = {
          "message"=>"Argument 'source' on InputObject 'DairyProductInput' has an invalid value. Expected type 'DairyAnimal!'.",
          "locations"=>[{"line"=>6, "column"=>39}],
          "path"=>["query getCheese", "badSource", "product", 0, "source"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"InputObject", "argumentName"=>"source"},
        }
        assert_includes(errors, input_object_field_error)

        missing_required_field_error = {
          "message"=>"Argument 'product' on Field 'missingSource' has an invalid value. Expected type '[DairyProductInput]'.",
          "locations"=>[{"line"=>7, "column"=>7}],
          "path"=>["query getCheese", "missingSource", "product"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"product"}
        }
        assert_includes(errors, missing_required_field_error)

        fragment_error = {
          "message"=>"Argument 'source' on Field 'similarCheese' has an invalid value. Expected type '[DairyAnimal!]!'.",
          "locations"=>[{"line"=>13, "column"=>7}],
          "path"=>["fragment cheeseFields", "similarCheese", "source"],
          "extensions"=> {"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"source"}
        }
        assert_includes(errors, fragment_error)
      end
    end
  end

  describe "using input objects for enums it adds an error" do
    let(:query_string) { <<-GRAPHQL
      {
        yakSource: searchDairy(product: [{source: {a: 1, b: 2}, fatContent: 1.1}]) { __typename }
      }
    GRAPHQL
    }
    it "works with error bubbling disabled" do
      without_error_bubbling(schema) do
        assert_equal 1, errors.length
      end
    end
    it "works with error bubbling enabled" do
      with_error_bubbling(schema) do
        # TODO:
        # It's annoying that this error cascades up, there should only be one:
        assert_equal 2, errors.length
      end
    end
  end

  describe "null value" do
    describe "nullable arg" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: Int): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: null)
        }
      |}

      it "finds no errors" do
        assert_equal [], errors
      end
    end

    describe "non-nullable arg" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: Int!): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: null)
        }
      |}

      it "finds error" do
        assert_equal [{
          "message"=>"Argument 'arg' on Field 'field' has an invalid value. Expected type 'Int!'.",
          "locations"=>[{"line"=>3, "column"=>11}],
          "path"=>["query", "field", "arg"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
        }], errors
      end
    end

    describe "non-nullable array" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: [Int!]): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: [null])
        }
      |}

      it "finds error" do
        assert_equal [{
          "message"=>"Argument 'arg' on Field 'field' has an invalid value. Expected type '[Int!]'.",
          "locations"=>[{"line"=>3, "column"=>11}],
          "path"=>["query", "field", "arg"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
        }], errors
      end
    end

    describe "array with nullable values" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: [Int]): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: [null])
        }
      |}

      it "finds no errors" do
        assert_equal [], errors
      end
    end

    describe "input object" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: Input): Int
          }

          input Input {
            a: Int
            b: Int!
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: {a: null, b: null})
        }
      |}

      describe "it finds errors" do
        it "works with error bubbling disabled" do
          without_error_bubbling(schema) do
            assert_equal 1, errors.length
            refute_includes errors, {
              "message"=>"Argument 'arg' on Field 'field' has an invalid value. Expected type 'Input'.",
              "locations"=>[{"line"=>3, "column"=>11}],
              "path"=>["query", "field", "arg"],
              "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
            }
            assert_includes errors, {
              "message"=>"Argument 'b' on InputObject 'Input' has an invalid value. Expected type 'Int!'.",
              "locations"=>[{"line"=>3, "column"=>22}],
              "path"=>["query", "field", "arg", "b"],
              "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"InputObject", "argumentName"=>"b"}
            }
          end
        end
        it "works with error bubbling enabled" do
          with_error_bubbling(schema) do
            assert_equal 2, errors.length
            assert_includes errors, {
              "message"=>"Argument 'arg' on Field 'field' has an invalid value. Expected type 'Input'.",
              "locations"=>[{"line"=>3, "column"=>11}],
              "path"=>["query", "field", "arg"],
              "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
            }

            assert_includes errors, {
              "message"=>"Argument 'b' on InputObject 'Input' has an invalid value. Expected type 'Int!'.",
              "locations"=>[{"line"=>3, "column"=>22}],
              "path"=>["query", "field", "arg", "b"],
              "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"InputObject", "argumentName"=>"b"}
            }
          end
        end
      end
    end
  end

  describe "dynamic fields" do
    let(:query_string) {"
      query {
        __type(name: 1) { name }
      }
    "}

    it "finds invalid argument types" do
      assert_includes(errors, {
        "message"=>"Argument 'name' on Field '__type' has an invalid value. Expected type 'String!'.",
        "locations"=>[{"line"=>3, "column"=>9}],
        "path"=>["query", "__type", "name"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"name"}
      })
    end
  end

  describe "custom error messages" do
    let(:schema) {
      CoerceTestTimeType ||= GraphQL::ScalarType.define do
        name "Time"
        description "Time since epoch in seconds"

        coerce_input ->(value, ctx) do
          begin
            Time.at(Float(value))
          rescue ArgumentError
            raise GraphQL::CoercionError, 'cannot coerce to Float'
          end
        end

        coerce_result ->(value, ctx) { value.to_f }
      end

      CoerceTestDeepTimeType ||= GraphQL::InputObjectType.define do
        name "range"
        description "Time range"
        argument :from, !CoerceTestTimeType
        argument :to, !CoerceTestTimeType
      end

      CoerceTestQueryType ||= GraphQL::ObjectType.define do
        name "Query"
        description "The query root of this schema"

        field :time do
          type CoerceTestTimeType
          argument :value, CoerceTestTimeType
          argument :range, CoerceTestDeepTimeType
          resolve ->(obj, args, ctx) { args[:value] }
        end
      end


      GraphQL::Schema.define do
        query CoerceTestQueryType
      end
    }

    let(:query_string) {%|
      query {
        time(value: "a")
      }
    |}

    describe "with a shallow coercion" do
      it "sets error message from a CoercionError if raised" do
        assert_equal 1, errors.length

        assert_includes errors, {
          "message"=> "cannot coerce to Float",
          "locations"=>[{"line"=>3, "column"=>9}],
          "path"=>["query", "time", "value"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"}
        }
      end
    end

    describe "with a deep coercion" do
      let(:query_string) {%|
        query {
          time(range: { from: "a", to: "b" })
        }
      |}

      from_error = {
        "message"=>"cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>23}],
        "path"=>["query", "time", "range", "from"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"},
      }

      to_error = {
        "message"=>"cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>23}],
        "path"=>["query", "time", "range", "to"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"},
      }

      bubbling_error = {
        "message"=>"cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>11}],
        "path"=>["query", "time", "range"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"},
      }

      describe "sets deep error message from a CoercionError if raised" do
        it "works with error bubbling enabled" do
          with_error_bubbling(schema) do
            assert_equal 3, errors.length
            assert_includes(errors, from_error)
            assert_includes(errors, to_error)
            assert_includes(errors, bubbling_error)
          end
        end

        it "works without error bubbling enabled" do
          without_error_bubbling(schema) do
            assert_equal 2, errors.length
            assert_includes(errors, from_error)
            assert_includes(errors, to_error)
            refute_includes(errors, bubbling_error)
          end
        end
      end
    end
  end
end
