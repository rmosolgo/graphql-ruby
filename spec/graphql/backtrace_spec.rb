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
      raise "Lazy Boom"
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

    it "annotates crashes from user code" do
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute <<-GRAPHQL, root_value: "Root"
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
      assert_includes err.message, "spec/graphql/backtrace_spec.rb:27", "It includes the original backtrace"
      assert_includes err.message, "more lines"
    end

    it "annotates errors inside lazy resolution" do
      err = assert_raises(GraphQL::Backtrace::TracedError) {
        schema.execute("query StrField { field2 { strField } __typename }")
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
  end

  # This will get brittle when execution code moves between files
  # but I'm not sure how to be sure that the backtrace contains the right stuff!
  def assert_backtrace_includes(backtrace, file:, method:)
    includes_tag = backtrace.any? { |s| s.include?(file) && s.include?("`" + method) }
    assert includes_tag, "Backtrace should include #{file} inside method #{method}"
  end
end
