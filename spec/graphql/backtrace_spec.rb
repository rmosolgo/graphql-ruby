# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Backtrace do
  class LazyError
    def raise_err
      raise "Lazy Boom"
    end
  end

  class ErrorAnalyzer
    def call(_memo, visit_type, irep_node)
      if irep_node.name == "raiseError"
        raise GraphQL::AnalysisError, "this should not be wrapped by a backtrace, but instead, returned to the client"
      end
    end
  end

  class NilInspectObject
    # Oops, this is evil, but it happens and we should handle it.
    def inspect; nil; end
  end

  class ErrorInstrumentation
    def self.before_query(_query)
    end

    def self.after_query(query)
      raise "Instrumentation Boom"
    end
  end

  let(:resolvers) {
    {
      "Query" => {
        "field1" => Proc.new { :something },
        "field2" => Proc.new { :something },
        "nilInspect" => Proc.new { NilInspectObject.new },
      },
      "Thing" => {
        "listField" => Proc.new { :not_a_list },
        "raiseField" => Proc.new { |o, a| raise("This is broken: #{a[:message]}") },
      },
      "OtherThing" => {
        "strField" => Proc.new { LazyError.new },
      },
    }
  }
  let(:schema) {
    defn = <<-GRAPHQL
    type Query {
      field1: Thing
      field2: OtherThing
      nilInspect: Thing
    }

    type Thing {
      listField: [OtherThing]
      raiseField(message: String!): Int
    }

    type OtherThing {
      strField: String
    }
    GRAPHQL
    GraphQL::Schema.from_definition(defn, default_resolve: resolvers).redefine {
      lazy_resolve(LazyError, :raise_err)
      query_analyzer(ErrorAnalyzer.new)
    }
  }

  let(:backtrace_schema) {
    schema.redefine(use: GraphQL::Backtrace)
  }

  describe "GraphQL backtrace helpers" do
    it "raises a TracedError when enabled" do
      assert_raises(GraphQL::Backtrace::TracedError) {
        backtrace_schema.execute("query BrokenList { field1 { listField { strField } } }")
      }

      assert_raises(NoMethodError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }
    end

    it "annotates crashes from user code" do
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        backtrace_schema.execute <<-GRAPHQL, root_value: "Root"
        query($msg: String = \"Boom\") {
          field1 {
            boomError: raiseField(message: $msg)
          }
        }
        GRAPHQL
      }

      # The original error info is present
      assert_instance_of RuntimeError, err.cause
      b = err.cause.backtrace
      assert_backtrace_includes(b, file: "backtrace_spec.rb", method: "block")
      assert_backtrace_includes(b, file: "execute.rb", method: "resolve_field")
      assert_backtrace_includes(b, file: "execute.rb", method: "resolve_field")
      assert_backtrace_includes(b, file: "execute.rb", method: "resolve_root_selection")

      # GraphQL backtrace is present
      expected_graphql_backtrace = [
        "3:13: Thing.raiseField as boomError",
        "2:11: Query.field1",
        "1:9: query",
      ]
      assert_equal expected_graphql_backtrace, err.graphql_backtrace

      # The message includes the GraphQL context
      rendered_table = [
        'Loc  | Field                         | Object     | Arguments           | Result',
        '3:13 | Thing.raiseField as boomError | :something | {"message"=>"Boom"} | #<RuntimeError: This is broken: Boom>',
        '2:11 | Query.field1                  | "Root"     | {}                  | {}',
        '1:9  | query                         | "Root"     | {"msg"=>"Boom"}     | ',
      ].join("\n")

      assert_includes err.message, rendered_table
      # The message includes the original error message
      assert_includes err.message, "This is broken: Boom"
      assert_includes err.message, "spec/graphql/backtrace_spec.rb:42", "It includes the original backtrace"
      assert_includes err.message, "more lines"
    end

    it "annotates errors from Query#result" do
      query_str = "query StrField { field2 { strField } __typename }"
      context = { backtrace: true }
      query = GraphQL::Query.new(schema, query_str, context: context)
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        query.result
      }
      assert_instance_of RuntimeError, err.cause
    end

    it "annotates errors inside lazy resolution" do
      # Test context-based flag
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute("query StrField { field2 { strField } __typename }", context: { backtrace: true })
      }
      assert_instance_of RuntimeError, err.cause
      b = err.cause.backtrace
      assert_backtrace_includes(b, file: "backtrace_spec.rb", method: "raise_err")
      assert_backtrace_includes(b, file: "field.rb", method: "lazy_resolve")
      assert_backtrace_includes(b, file: "lazy/resolve.rb", method: "block")

      expected_graphql_backtrace = [
        "1:27: OtherThing.strField",
        "1:18: Query.field2",
        "1:1: query StrField",
      ]

      assert_equal(expected_graphql_backtrace, err.graphql_backtrace)

      rendered_table = [
        'Loc  | Field               | Object     | Arguments | Result',
        '1:27 | OtherThing.strField | :something | {}        | #<RuntimeError: Lazy Boom>',
        '1:18 | Query.field2        | nil        | {}        | {strField: (unresolved)}',
        '1:1  | query StrField      | nil        | {}        | {field2: {...}, __typename: "Query"}',
      ].join("\n")
      assert_includes err.message, rendered_table
    end

    it "returns analysis errors to the client" do
      res = backtrace_schema.execute("query raiseError { __typename }")
      assert_equal "this should not be wrapped by a backtrace, but instead, returned to the client", res["errors"].first["message"]
    end

    it "always stringifies the #inspect response" do
      # test the schema plugin
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        backtrace_schema.execute("query { nilInspect { raiseField(message: \"pop!\") } }")
      }

      rendered_table = [
        'Loc  | Field            | Object | Arguments           | Result',
        '1:22 | Thing.raiseField |        | {"message"=>"pop!"} | #<RuntimeError: This is broken: pop!>',
        '1:9  | Query.nilInspect | nil    | {}                  | {}',
        '1:1  | query            | nil    | {}                  | {}',
      ].join("\n")

      assert_includes(err.message, rendered_table)
    end


    it "raises original exception instead of a TracedError when error does not occur during resolving" do
      instrumentation_schema = schema.redefine do
        instrument(:query, ErrorInstrumentation)
      end

      assert_raises(RuntimeError) {
        instrumentation_schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY, context: { backtrace: true })
      }
    end
  end

  # This will get brittle when execution code moves between files
  # but I'm not sure how to be sure that the backtrace contains the right stuff!
  def assert_backtrace_includes(backtrace, file:, method:)
    includes_tag = backtrace.any? { |s| s.include?(file) && s.include?("`" + method) }
    assert includes_tag, "Backtrace should include #{file} inside method #{method}"
  end
end
