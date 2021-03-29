# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::ArgumentsAreDefined do
  include StaticValidationHelpers
  include ErrorBubblingHelpers

  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { source }
      cheese(silly: false, id: 2) { source }
      searchDairy(product: [{wacky: 1}]) { ...cheeseFields }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: SHEEP, nonsense: 1) { __typename }
      id @skip(something: 3.4, if: false)
    }
  "}

  describe "finds undefined arguments to fields and directives" do
    it "works with error bubbling" do
      with_error_bubbling(Dummy::Schema) do
        # There's an extra error here, the unexpected argument on "DairyProductInput"
        # triggers _another_ error that the field expected a different type
        assert_equal(6, errors.length)

        query_root_error = {
          "message"=>"Field 'cheese' doesn't accept argument 'silly'",
          "locations"=>[{"line"=>4, "column"=>14}],
          "path"=>["query getCheese", "cheese", "silly"],
          "extensions"=>{
            "code"=>"argumentNotAccepted",
            "name"=>"cheese",
            "typeName"=>"Field",
            "argumentName"=>"silly"
          },
        }
        assert_includes(errors, query_root_error)

        input_obj_record = {
          "message"=>"InputObject 'DairyProductInput' doesn't accept argument 'wacky'",
          "locations"=>[{"line"=>5, "column"=>30}],
          "path"=>["query getCheese", "searchDairy", "product", 0, "wacky"],
          "extensions"=>{
            "code"=>"argumentNotAccepted",
            "name"=>"DairyProductInput",
            "typeName"=>"InputObject",
            "argumentName"=>"wacky"
          },
        }
        assert_includes(errors, input_obj_record)

        fragment_error = {
          "message"=>"Field 'similarCheese' doesn't accept argument 'nonsense'",
          "locations"=>[{"line"=>9, "column"=>36}],
          "path"=>["fragment cheeseFields", "similarCheese", "nonsense"],
          "extensions"=>{
            "code"=>"argumentNotAccepted",
            "name"=>"similarCheese",
            "typeName"=>"Field",
            "argumentName"=>"nonsense",
          },
        }
        assert_includes(errors, fragment_error)

        directive_error = {
          "message"=>"Directive 'skip' doesn't accept argument 'something'",
          "locations"=>[{"line"=>10, "column"=>16}],
          "path"=>["fragment cheeseFields", "id", "something"],
          "extensions"=>{
            "code"=>"argumentNotAccepted",
            "name"=>"skip",
            "typeName"=>"Directive",
            "argumentName"=>"something",
          },
        }
        assert_includes(errors, directive_error)
      end
    end

    it "works without error bubbling" do
      without_error_bubbling(Dummy::Schema) do
        assert_equal(5, errors.length)

        extra_error = {
          "message"=>"Argument 'product' on Field 'searchDairy' has an invalid value. Expected type '[DairyProductInput]'.",
          "locations"=>[{"line"=>5, "column"=>7}],
          "path"=>["query getCheese", "searchDairy", "product"]
        }
        refute_includes(errors, extra_error)
      end
    end
  end

  describe "dynamic fields" do
    let(:query_string) {"
      query {
        __type(somethingInvalid: 1) { name }
      }
    "}

    it "finds undefined arguments" do
      assert_includes(errors, {
        "message"=>"Field '__type' doesn't accept argument 'somethingInvalid'",
        "locations"=>[{"line"=>3, "column"=>16}],
        "path"=>["query", "__type", "somethingInvalid"],
        "extensions"=>{"code"=>"argumentNotAccepted", "name"=>"__type", "typeName"=>"Field", "argumentName"=>"somethingInvalid"}
      })
    end
  end

  describe "error references argument's parent" do
    let(:validator) { GraphQL::StaticValidation::Validator.new(schema: schema) }
    let(:query) { GraphQL::Query.new(schema, query_string) }
    let(:errors) { validator.validate(query)[:errors] }
    let(:query_string) {"
      query {
        cheese(silly: true, id: 1) { source }
        milk(id: 1) { source @skip(something: 3.4, if: false) }
      }
    "}

    it "works with field" do
      query_cheese_field = schema.types['Query'].fields['cheese']
      error = errors.find { |error| error.argument_name == 'silly' }

      assert_equal query_cheese_field, error.parent
    end

    it "works with directive" do
      skip_directive = schema.directives['skip']
      error = errors.find { |error| error.argument_name == 'something' }

      assert_equal skip_directive, error.parent
    end
  end
end
