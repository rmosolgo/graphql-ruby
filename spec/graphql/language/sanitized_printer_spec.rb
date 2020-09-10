# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::SanitizedPrinter do
  module SanitizeTest
    class Color < GraphQL::Schema::Enum
      value "RED"
      value "BLUE"
    end

    class Url < GraphQL::Schema::Scalar
    end

    class ExampleInput < GraphQL::Schema::InputObject
      argument :string, String, required: true
      argument :id, ID, required: true
      argument :int, Int, required: true
      argument :float, Float, required: true
      argument :enum, Color, required: true
      argument :input_object, ExampleInput, required: false
      argument :url, Url, required: true
    end

    class Query < GraphQL::Schema::Object
      field :inputs, String, null: false do
        argument :string, String, required: true
        argument :id, ID, required: true
        argument :int, Int, required: true
        argument :float, Float, required: true
        argument :enum, Color, required: true
        argument :input_object, ExampleInput, required: true
        argument :url, Url, required: true
      end

      field :strings, String, null: false do
        argument :strings, [String], required: true
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
  end

  def sanitize_string(query_string, **options)
    query = GraphQL::Query.new(
      SanitizeTest::Schema,
      query_string,
      **options
    )
    query.sanitized_query_string
  end

  it "replaces strings with redacted" do
    query_str = '
    {
      inputs(
        string: "string",
        id: "id",
        int: 1,
        float: 2.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: "string"
          id: "id"
          int: 1
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
        }
      )
    }
    '

    expected_query_string = 'query {
  inputs(string: "<REDACTED>", id: "id", int: 1, float: 2.0, url: "<REDACTED>", enum: RED, inputObject: {string: "<REDACTED>", id: "id", int: 1, float: 2.0, url: "<REDACTED>", enum: RED})
}'
    assert_equal expected_query_string, sanitize_string(query_str)
  end

  it "inlines variables AND redacts their values" do
    query_str = '
    query($string1: String!, $string2: String = "str2", $inputObject: ExampleInput!) {
      inputs(
        string: $string1,
        id: "id1",
        int: 1,
        float: 1.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: $string2
          id: "id2"
          int: 2
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
          inputObject: $inputObject
        }
      )
    }
    '

    variables = {
      "string1" => "str1",
      "inputObject" => {
        "string" => "str3",
        "id" => "id3",
        "int" => 3,
        "float" => 3.3,
        "url" => "three.com",
        "enum" => "BLUE"
      }
    }

    expected_query_string = 'query {
  inputs(' +
    'string: "<REDACTED>", id: "id1", int: 1, float: 1.0, url: "<REDACTED>", enum: RED, inputObject: {' +
    'string: "<REDACTED>", id: "id2", int: 2, float: 2.0, url: "<REDACTED>", enum: RED, inputObject: {' +
    'string: "<REDACTED>", id: "id3", int: 3, float: 3.3, url: "<REDACTED>", enum: BLUE}})
}'
    assert_equal expected_query_string, sanitize_string(query_str, variables: variables)
  end

  it "redacts from lists" do
    query_str_1 = '{ strings(strings: ["s1", "s2"]) }'
    query_str_2 = 'query($strings: [String!]!) { strings(strings: $strings) }'
    expected_query_string = 'query {
  strings(strings: ["<REDACTED>", "<REDACTED>"])
}'

    assert_equal expected_query_string, sanitize_string(query_str_1)
    assert_equal expected_query_string, sanitize_string(query_str_2, variables: { "strings" => ["s1", "s2"]})
  end

  it "returns nil on invalid queries" do
    assert_nil sanitize_string "{ __typename "
  end
end

