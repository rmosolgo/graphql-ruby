# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Backtrace do
  before {
    GraphQL::Backtrace.enable
  }

  after {
    GraphQL::Backtrace.disable
  }

  class LazyError
    def raise_err
      raise "Boom"
    end
  end

  let(:resolvers) {
    {
      "Query" => {
        "field1" => Proc.new { :something },
        "field2" => Proc.new { :something },
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
    }
  }

  describe "GraphQL backtrace helpers" do
    it "raises a TracedError when enabled" do
      assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }

      GraphQL::Backtrace.disable

      assert_raises(NoMethodError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }
    end

    it "cleans up its own stack" do
      # Starts clean
      assert_equal 0, GraphQL::Backtrace.execution_context.size

      # Cleaned up after normal query
      schema.execute("{__schema{types{name}}}")

      assert_equal 0, GraphQL::Backtrace.execution_context.size

      # Cleaned up after error
      assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }

      assert_equal 0, GraphQL::Backtrace.execution_context.size
    end

    it "annotates crashes from user code" do
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute <<-GRAPHQL
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
        "execute_field:       Thing.raiseField @ [3:13] as boomError",
        "execute_field:       Query.field1 @ [2:11]",
        "execute_query:       query @ [1:9]",
        "execute_multiplex:   query @ [1:9]",
      ]
      assert_equal expected_graphql_backtrace, err.graphql_backtrace

      # The message includes the GraphQL context
      rendered_table = [
        'Event             | Field                                  | Object     | Arguments           | Result',
        'execute_field     | Thing.raiseField @ [3:13] as boomError | :something | {"message"=>"Boom"} | nil',
        'execute_field     | Query.field1 @ [2:11]                  | nil        | {}                  | {}',
        'execute_query     | query @ [1:9]                          | nil        | {"msg"=>"Boom"}     | ',
        'execute_multiplex | query @ [1:9]                          | nil        | {"msg"=>"Boom"}     | ',
      ].join("\n")

      assert_includes err.message, rendered_table
      # The message includes the original error message
      assert_includes err.message, "This is broken: Boom"
    end

    it "annotates errors inside lazy resolution" do
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute("query StrField { field2 { strField } }")
      }
      assert_instance_of RuntimeError, err.cause
      b = err.cause.backtrace
      assert_backtrace_includes(b, file: "backtrace_spec.rb", method: "raise_err")
      assert_backtrace_includes(b, file: "field.rb", method: "lazy_resolve")
      assert_backtrace_includes(b, file: "lazy/resolve.rb", method: "block")

      expected_graphql_backtrace = [
        "execute_field_lazy:  OtherThing.strField @ [1:27]",
        "execute_query_lazy:  query StrField @ [1:1]",
        "execute_multiplex:   query StrField @ [1:1]",
      ]


      assert_equal(expected_graphql_backtrace, err.graphql_backtrace)
    end
  end

  # This will get brittle when execution code moves between files
  # but I'm not sure how to be sure that the backtrace contains the right stuff!
  def assert_backtrace_includes(backtrace, file:, method:)
    includes_tag = backtrace.any? { |s| s.include?(file) && s.include?("`" + method) }
    assert includes_tag, "Backtrace should include #{file} inside method #{method}"
  end
end
