# frozen_string_literal: true
require "spec_helper"

if RUN_RACTOR_TESTS
  describe GraphQL::Schema::RactorShareable do
    class RactorExampleSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :i, Int, fallback_value: 1
      end
      query(Query)
      validate_timeout(nil) # Timeout doesn't work in non-main Ractors
      use GraphQL::Schema::Visibility, preload: true, profiles: { nil => {} }

      extend GraphQL::Schema::RactorShareable
    end

    it "can access some basic GraphQL objects" do
      ractor = Ractor.new do
        parent = Ractor.receive
        query = GraphQL::Query.new(RactorExampleSchema, "{ __typename }" )
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
      assert_equal({"data" => {"__typename" => "Query"}}, Ractor.receive)
    end

    it "can get schema members by name" do
      skip "Doesn't work yet"
      ractor = Ractor.new do
        parent = Ractor.receive
        parent.send(RactorExampleSchema.get_field("Query", "__typename").class.name)
      rescue StandardError => err
        puts err.message
        puts err.backtrace
        parent.send(err)
      end
      ractor.send(Ractor.current)
      assert_equal "GraphQL::Field", Ractor.receive
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

      assert_equal "Query", new_schema.execute("{ __typename }")["data"]["__typename"]
    end
  end
end
