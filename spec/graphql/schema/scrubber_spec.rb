# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Scrubber do
  SCRUBBER_SCHEMA_DEFN = <<-GRAPHQL
  type Query {
    field1(
      int: Int,
      float: Float,
      bool: Boolean,
      id: ID,
      string: String,
      inputObj: Input,
      inputObjs: [Input],
    ): String
  }

  type Mutation {
    field1(
      int: Int,
      float: Float,
      bool: Boolean,
      id: ID,
      string: String,
      inputObj: Input,
      inputObjs: [Input],
    ): String
  }

  input Input {
    int: Int,
    float: Float,
    bool: Boolean,
    id: ID,
    string: String,
    inputObj: Input,
    inputObjs: [Input],
  }
  GRAPHQL

  let(:schema) {
    s_opts = scrub_variables
    GraphQL::Schema.from_definition(SCRUBBER_SCHEMA_DEFN).redefine do
      scrub(s_opts)
    end
  }

  let(:query_string) {
    <<-GRAPHQL
    query($int: Int, $float: Float, $bool: Boolean, $id: ID, $string: String, $inputObj: Input){
      field1(
        int: $int
        float: $float
        bool: $bool
        id: $id
        string: $string
        inputObj: $inputObj
      )
    }
    GRAPHQL
  }
  let(:variables) {
    {
      "int" => 1,
      "float" => 2.2,
      "bool" => true,
      "id" => "1234",
      "string" => "hello",
      "inputObj" => {
        "int" => 1,
        "float" => 2.2,
        "bool" => true,
        "id" => "1234",
        "string" => "hello",
        "inputObjs" => [
          {
            "int" => 1,
            "float" => 2.2,
            "bool" => true,
            "id" => "1234",
            "string" => "hello",
          }
        ]
      }
    }
  }
  let(:query) {
    GraphQL::Query.new(schema, query_string, variables: variables)
  }

  let(:scrubbed_variables) {
    query.scrubbed_variables
  }

  let(:mutation) {
    mutation_string = query_string.sub("query", "mutation")
    GraphQL::Query.new(schema, mutation_string, variables: variables)
  }

  let(:scrubbed_mutation_variables) {
    mutation.scrubbed_variables
  }

  describe "whitelist" do
    let(:scrub_variables) {
      { whitelist: [:int, :float, :bool, :inputObj] }
    }
    let(:expected_query_variables) {
      {
        "int" => 1,
        "float" => 2.2,
        "bool" => true,
        "id" => "*****",
        "string" => "*****",
        "inputObj" => {
          "int" => 1,
          "float" => 2.2,
          "bool" => true,
          "id" => "*****",
          "string" => "*****",
          "inputObjs" => "*****",
        }
      }
    }
    it "only shows keys on the whitelist" do
      assert_equal(expected_query_variables, scrubbed_variables)
      # Same result on mutations:
      assert_equal(expected_query_variables, scrubbed_mutation_variables)
    end

    describe "mutations: false" do
      let(:scrub_variables) {
        { whitelist: [:int, :float, :bool, :inputObj], mutations: false }
      }

      it "rejects _everything_ on a mutation" do
        expected_mutation_variables = {
          "int" => "*****",
          "float" => "*****",
          "bool" => "*****",
          "id" => "*****",
          "string" => "*****",
          "inputObj" => "*****"
        }
        assert_equal(expected_mutation_variables, scrubbed_mutation_variables)
        # Original result holds for queries:
        assert_equal(expected_query_variables, scrubbed_variables)
      end
    end
  end

  describe "blacklist" do
    let(:scrub_variables) {
      { blacklist: [:int, :float, :bool] }
    }
    let(:expected_query_variables) {
      {
        "int" => "*****",
        "float" => "*****",
        "bool" => "*****",
        "id" => "1234",
        "string" => "hello",
        "inputObj" => {
          "int" => "*****",
          "float" => "*****",
          "bool" => "*****",
          "id" => "1234",
          "string" => "hello",
          "inputObjs" => [
            {
              "int" => "*****",
              "float" => "*****",
              "bool" => "*****",
              "id" => "1234",
              "string" => "hello",
            }
          ]
        }
      }
    }

    it "rejects keys on the blacklist" do
      assert_equal expected_query_variables, scrubbed_variables
    end
  end

  describe "no whitelist or blacklist" do
    let(:scrub_variables) {
      {}
    }
    it "returns everything" do
      assert_equal(variables, scrubbed_variables)
      assert_equal(variables, scrubbed_mutation_variables)
    end

    describe "when mutations: false" do
      let(:scrub_variables) {
        {mutations: false}
      }
      it "returns nothing" do
        expected_mutation_variables = {
          "int" => "*****",
          "float" => "*****",
          "bool" => "*****",
          "id" => "*****",
          "string" => "*****",
          "inputObj" => "*****"
        }
        assert_equal(expected_mutation_variables, scrubbed_mutation_variables)
        # Query vars are unaffected:
        assert_equal(variables, scrubbed_variables)
      end
    end
  end

  describe "whitelist _and_ blacklist" do
    let(:scrub_variables) {
      {whitelist: [:id], blacklist: [:string]}
    }
    it "raises an Argument error" do
      assert_raises ArgumentError do
        scrubbed_variables
      end
    end
  end
end
