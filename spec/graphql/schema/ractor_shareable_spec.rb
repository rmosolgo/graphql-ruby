# frozen_string_literal: true
require "spec_helper"

if RUN_RACTOR_TESTS
  describe GraphQL::Schema::RactorShareable do
    class RactorExampleSchema < GraphQL::Schema
      class CustomError < RuntimeError; end

      class SomeEnum < GraphQL::Schema::Enum
        value :A
        value :B
      end
      class Query < GraphQL::Schema::Object
        field :i, Int, fallback_value: 1
        field :e, SomeEnum, fallback_value: "A"

        field :error_1, String

        def error_1
          raise GraphQL::ExecutionError, "Boom!"
        end

        field :error_2, String

        def error_2
          raise CustomError
        end
      end

      query(Query)
      validate_timeout(nil) # Timeout doesn't work in non-main Ractors
      use GraphQL::Schema::Visibility, preload: true, profiles: { nil => {} }
      rescue_from(CustomError) { "Something went wrong" }
      extend GraphQL::Schema::RactorShareable
    end

    it "can access some basic GraphQL objects" do
      ractor = Ractor.new do
        parent = Ractor.receive
        query = GraphQL::Query.new(RactorExampleSchema, "{ __typename i e }" )
        parent.send(query.class.name)
        result = query.result.to_h
        parent.send(result)
      rescue StandardError => err
        puts err.message
        puts err.backtrace
        parent.send(err)
      end
      ractor.send(Ractor.current)
      assert_equal "GraphQL::Query", Ractor.receive
      expected_result = {
        "data" => {
          "__typename" => "Query",
          "i" => 1,
          "e" => "A"
        }
      }
      assert_graphql_equal expected_result, Ractor.receive
    end

    it "can handle runtime errors" do
      ractor = Ractor.new do
        parent = Ractor.receive
        result = RactorExampleSchema.execute("{ error1 error2 }")
        parent.send(result.to_h)
      rescue StandardError => err
        puts err.message
        puts err.backtrace
        parent.send(err)
      end
      ractor.send(Ractor.current)
      expected_result = {
        "errors" => [
          {
            "message" => "Boom!",
            "locations" => [{"line" => 1, "column" => 3}],
            "path" => ["error1"]
          }
        ],
        "data" => {
          "error1" => nil,
          "error2" => "Something went wrong"
        }
      }
      assert_graphql_equal expected_result, Ractor.receive
    end

    it "can get schema members by name" do
      ractor = Ractor.new do
        parent = Ractor.receive
        parent.send(RactorExampleSchema.get_field("Query", "__typename").class.name)
        parent.send(RactorExampleSchema.get_type("Query").class.name)
        parent.send(RactorExampleSchema.get_field("Query", "i").class.name)
        parent.send([
          RactorExampleSchema.query.graphql_name,
          RactorExampleSchema.mutation
        ])
      rescue StandardError => err
        puts err.message
        puts err.backtrace
        parent.send(err.message)
      end
      ractor.send(Ractor.current)
      assert_equal "GraphQL::Schema::Field", Ractor.receive
      assert_equal "Class", Ractor.receive
      assert_equal "GraphQL::Schema::Field", Ractor.receive
      assert_equal ["Query", nil], Ractor.receive
    end

    it "can parse a schema string to ast" do
      schema_str = Dummy::Schema.to_definition
      ractor = Ractor.new do
        parent = Ractor.receive
        inner_schema_str = Ractor.receive
        schema_ast = GraphQL.parse(inner_schema_str)
        Ractor.make_shareable(schema_ast)
        parent.send(schema_ast)
      end
      ractor.send(Ractor.current)
      ractor.send(schema_str)
      parsed_schema_ast = Ractor.receive
      assert_equal schema_str.chomp, parsed_schema_ast.to_query_string
    end

    it "doesn't poison other schemas" do
      new_schema = Class.new(GraphQL::Schema) do
        q = Class.new(GraphQL::Schema::Object) {
          graphql_name("Query")
          field :f, Float
        }
        query(q)
      end

      assert_equal "Query", new_schema.execute("{ __typename @include(if: true) }")["data"]["__typename"]
    end
  end
end
