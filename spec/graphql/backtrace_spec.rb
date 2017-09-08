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
    defn = <<~GRAPHQL
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

  describe "graphql context in backtraces" do
    it "annotates when enabled" do
      err = assert_raises(NoMethodError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }
      assert err.backtrace.any? { |s| s.include?("GraphQL: ")}
      GraphQL::Backtrace.disable

      err = assert_raises(NoMethodError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }
      refute err.backtrace.any? { |s| s.include?("GraphQL: ")}
    end

    it "cleans up its own stack" do
      # Starts clean
      assert_equal 0, GraphQL::Backtrace.backtrace_context.compact.size
      assert_equal 0, GraphQL::Backtrace.execution_context.size

      # Cleaned up after normal query
      schema.execute("{__schema{types{name}}}")

      assert_equal 0, GraphQL::Backtrace.backtrace_context.compact.size
      assert_equal 0, GraphQL::Backtrace.execution_context.size

      # Cleaned up after error
      assert_raises(NoMethodError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }

      assert_equal 0, GraphQL::Backtrace.backtrace_context.compact.size
      assert_equal 0, GraphQL::Backtrace.execution_context.size
    end


    it "annotates NoMethodErrors" do
      schema
      err = assert_raises(NoMethodError) {
        schema.execute("query BrokenList { field1 { listField { strField } } }")
      }
      assert_backtrace_includes(err.backtrace, file: "execute.rb", method: "resolve_value", annotation: "Thing.listField")
      assert_backtrace_includes(err.backtrace, file: "execute.rb", method: "resolve_field", annotation: "Thing.listField")
      assert_backtrace_includes(err.backtrace, file: "execute.rb", method: "resolve_value", annotation: "Query.field1")
      assert_backtrace_includes(err.backtrace, file: "execute.rb", method: "resolve_field", annotation: "Query.field1")
      assert_backtrace_includes(err.backtrace, file: "execute.rb", method: "resolve_root_selection", annotation: "query BrokenList")
      assert_backtrace_includes(err.backtrace, file: "multiplex.rb", method: "begin_query", annotation: "query BrokenList")
    end

    it "annotates crashes from user code" do
      err = assert_raises(RuntimeError) {
        pp schema.execute("{ field1 { boomError: raiseField(message: \"Boom\") } }")
      }
      b = err.backtrace
      assert_backtrace_includes(b, file: "backtrace_spec.rb", method: "block", annotation: "Thing.raiseField(message: \"Boom\") (as boomError)" )
      assert_backtrace_includes(b, file: "execute.rb", method: "resolve_field", annotation: "Thing.raiseField(message: \"Boom\") (as boomError)")
      assert_backtrace_includes(b, file: "execute.rb", method: "resolve_field", annotation: "Query.field1")
      assert_backtrace_includes(b, file: "execute.rb", method: "resolve_root_selection", annotation: "query <Anonymous>")

    end

    it "annotates errors inside lazy resolution" do
      err = assert_raises(RuntimeError) {
        pp schema.execute("{ field2 { strField } }")
      }
      b = err.backtrace
      assert_backtrace_includes(b, file: "backtrace_spec.rb", method: "raise_err", annotation: "OtherThing.strField")
      assert_backtrace_includes(b, file: "field.rb", method: "lazy_resolve", annotation: "OtherThing.strField")
      assert_backtrace_includes(b, file: "lazy/resolve.rb", method: "block", annotation: "OtherThing.strField")
    end
  end

  # This will get brittle when execution code moves between files
  # but I'm not sure how to be sure that the backtrace contains the right stuff!
  def assert_backtrace_includes(backtrace, file:, method:, annotation:)
    is_annotated = backtrace.any? { |s| s.include?(file) && s.include?("`" + method) && s.include?("GraphQL: " + annotation) }
    assert is_annotated, "Backtrace should tag of '#{annotation}' from #{file} inside method #{method}"
  end
end
