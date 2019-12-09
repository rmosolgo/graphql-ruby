# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Context do
  CTX = []
  before { CTX.clear }

  let(:parent_info_type) {
    GraphQL::ObjectType.define {
      name "ParentInfo"
      field :object, types.String do
        resolve ->(o, a, c) { c.parent.parent.object }
      end
      field :objectClassName, types.String do
        resolve ->(o, a, c) { c.parent.parent.object.class.name }
      end
      field :valueClassName, types.String do
        resolve ->(o, a, c) { c.parent.parent.value.class.name }
      end
      field :value, types.String do
        resolve ->(o, a, c) { c.parent.parent.value.to_s }
      end
    }
  }
  let(:backtrace_type) {
    GraphQL::ObjectType.define do
      name "Backtrace"
      field :backtraceEntry, types.String do
        argument :idx, !types.Int
        resolve ->(o, a, c) { c.backtrace[a[:idx]] }
      end
      field :backtraceArray, types[types.String] do
        resolve ->(o, a, c) { c.backtrace.to_a }
      end
      field :backtraceTable, types.String do
        resolve ->(o, a, c) { c.backtrace.inspect }
      end
    end
  }
  let(:query_type) {
    parent_info = parent_info_type
    backtrace = backtrace_type
    GraphQL::ObjectType.define {
      name "Query"
      field :context, types.String do
        argument :key, !types.String
        resolve ->(target, args, ctx) { ctx[args[:key]] }
      end
      field :contextAstNodeName, types.String do
        resolve ->(target, args, ctx) { ctx.ast_node.class.name }
      end
      field :contextIrepNodeName, types.String do
        resolve ->(target, args, ctx) { ctx.irep_node.class.name }
      end
      field :queryName, types.String do
        resolve ->(target, args, ctx) { ctx.query.class.name }
      end

      field :pushContext, types.Int do
        resolve ->(t,a,c) { CTX << c; 1 }
      end

      field :pushQueryError, types.Int do
        resolve ->(t,a,c) {
          c.query.context.add_error(GraphQL::ExecutionError.new("Query-level error"))
          1
        }
      end

      field :parentInfo, parent_info, resolve: ->(o,a,c) { :noop }
      field :backtrace, backtrace, resolve: Proc.new { :noop }
    }
  }

  let(:schema) { GraphQL::Schema.define(query: query_type, mutation: nil)}
  let(:result) { schema.execute(query_string, root_value: "rootval", context: {"some_key" => "some value"})}

  describe "access to parent context" do
    let(:query_string) { %|
      {
        parentInfo {
          value
          valueClassName
          object
          objectClassName
        }
      }
    |}

    it "exposes the parent object" do
      expected = {
        "data" => {
          "parentInfo" => {
            "objectClassName" => "String",
            "object" => "rootval",
            "value" => "{}",
            "valueClassName" => "Hash",
          }
        }
      }
      assert_equal(expected, result)
    end
  end

  describe "access to passed-in values" do
    let(:query_string) { %|
      query getCtx { context(key: "some_key") }
    |}

    it "passes context to fields" do
      expected = {"data" => {"context" => "some value"}}
      assert_equal(expected, result)
    end
  end

  describe "access to the AST node" do
    let(:query_string) { %|
      query getCtx { contextAstNodeName }
    |}

    it "provides access to the AST node" do
      expected = {"data" => {"contextAstNodeName" => "GraphQL::Language::Nodes::Field"}}
      assert_equal(expected, result)
    end
  end

  describe "#backtrace" do
    let(:query_string) { %|
      query {
        backtrace {
          b1: backtraceEntry(idx: 0)
          b2: backtraceEntry(idx: 1)
          b3: backtraceEntry(idx: 2)
          backtraceArray
          backtraceTable
        }
        pushContext
      }
    |}

    it "exposes the GraphQL backtrace" do
      backtrace_result = result.fetch("data").fetch("backtrace")
      assert_equal "4:11: Backtrace.backtraceEntry as b1", backtrace_result.fetch("b1")
      assert_equal "3:9: Query.backtrace", backtrace_result.fetch("b2")
      assert_equal "2:7: query", backtrace_result.fetch("b3")
      assert_equal ["7:11: Backtrace.backtraceArray", "3:9: Query.backtrace", "2:7: query"], backtrace_result.fetch("backtraceArray")
      expected_table = [
        'Loc  | Field                    | Object    | Arguments | Result',
        '8:11 | Backtrace.backtraceTable | :noop     | {}        | nil',
        '3:9  | Query.backtrace          | "rootval" | {}        | {b1: "4:11: Backtrace.backtraceEntry as b1", b2: "3:9: Query.backtrace", b3: "2:7: query", backtr...',
        '2:7  | query                    | "rootval" | {}        | {}',
        '',
      ].join("\n")
      assert_equal expected_table, backtrace_result.fetch("backtraceTable")

      expected_table_2 = <<-TABLE
Loc  | Field             | Object    | Arguments | Result
10:9 | Query.pushContext | "rootval" | {}        | 1
2:7  | query             | "rootval" | {}        | {backtrace: {...}, pushContext: 1}
TABLE

      ctx = CTX.last
      assert_equal expected_table_2, ctx.backtrace.to_s
    end
  end

  describe "access to the InternalRepresentation node" do
    let(:query_string) { %|
      query getCtx { contextIrepNodeName }
    |}

    it "provides access to the AST node" do
      expected = {"data" => {"contextIrepNodeName" => "GraphQL::InternalRepresentation::Node"}}
      assert_equal(expected, result)
    end
  end

  describe "access to the query" do
    let(:query_string) { %|
      query getCtx { queryName }
    |}

    it "provides access to the AST node" do
      expected = {"data" => {"queryName" => "GraphQL::Query"}}
      assert_equal(expected, result)
    end
  end

  describe "empty values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil, object: nil) }

    it "returns returns nil and reports key? => false" do
      assert_equal(nil, context[:some_key])
      assert_equal(false, context.key?(:some_key))
      assert_raises(KeyError) { context.fetch(:some_key) }
    end
  end

  describe "assigning values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil, object: nil) }

    it "allows you to assign new contexts" do
      assert_equal(nil, context[:some_key])
      context[:some_key] = "wow!"
      assert_equal("wow!", context[:some_key])
    end

    describe "namespaces" do
      let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: 1}, object: nil) }

      it "doesn't conflict with base values" do
        ns = context.namespace(:stuff)
        ns[:b] = 2
        assert_equal({a: 1}, context.to_h)
        assert_equal({b: 2}, context.namespace(:stuff))
      end
    end
  end

  describe "read values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: {b: 1}}, object: nil) }

    it "allows you to read values of contexts using []" do
      assert_equal({b: 1}, context[:a])
    end

    it "allows you to read values of contexts using dig" do
      if RUBY_VERSION >= '2.3.0'
        assert_equal(1, context.dig(:a, :b))
      else
        assert_raises NoMethodError do
          context.dig(:a, :b)
        end
      end
    end
  end

  describe "splatting" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: {b: 1}}, object: nil) }

    let(:splat) { ->(**context) { context } }

    it "runs successfully" do
      assert_equal({a: { b: 1 }}, splat.call(context))
    end
  end

  describe "accessing context after the fact" do
    let(:query_string) { %|
      { pushContext }
    |}

    it "preserves path information" do
      assert_equal 1, result["data"]["pushContext"]
      last_ctx = CTX.pop
      assert_equal ["pushContext"], last_ctx.path
      err = GraphQL::ExecutionError.new("Test position info")
      last_ctx.add_error(err)
      assert_equal ["pushContext"], err.path
      assert_equal [2, 9], [err.ast_node.line, err.ast_node.col]
    end
  end

  describe "query-level errors" do
    let(:query_string) { %|
      { pushQueryError }
    |}

    it "allows query-level errors" do
      expected_err = { "message" => "Query-level error" }
      assert_equal [expected_err], result["errors"]
    end
  end

  describe "custom context class" do
    it "can be specified" do
      query_str = '{
        inspectContext
        find(id: "Musician/Herbie Hancock") {
          ... on Musician {
            inspectContext
          }
        }
      }'
      res = Jazz::Schema.execute(query_str, context: { magic_key: :ignored, normal_key: "normal_value" })
      expected_values = ["custom_method", "magic_value", "normal_value"]
      expected_values_with_nil = expected_values + [nil]
      assert_equal expected_values, res["data"]["inspectContext"]
      assert_equal expected_values_with_nil, res["data"]["find"]["inspectContext"]
    end
  end

  describe "scoped context" do
    class LazyBlock
      def initialize
        @get_value = Proc.new
      end

      def value
        @get_value.call
      end
    end

    class ContextQuery < GraphQL::Schema::Object
      field :get_scoped_context, String, null: true do
        argument :key, String, required: true
        argument :lazy, Boolean, required: false, default_value: false
      end

      def get_scoped_context(key:, lazy:)
        result = LazyBlock.new {
          context[key]
        }
        return result if lazy
        result.value
      end

      field :set_scoped_context, ContextQuery, null: false do
        argument :key, String, required: true
        argument :value, String, required: true
        argument :lazy, Boolean, required: false, default_value: false
      end

      def set_scoped_context(key:, value:, lazy:)
        if lazy
          LazyBlock.new {
            context.scoped_merge!(key => value)
            LazyBlock.new {
              self
            }
          }
        else
          context.scoped_merge!(key => value)
          self
        end
      end
    end

    class ContextSchema < GraphQL::Schema
      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
      query(ContextQuery)
      lazy_resolve(LazyBlock, :value)
    end

    it "can be set and does not leak to sibling fields" do
      query_str = %|
        {
          before: getScopedContext(key: "a")
          firstSetOuter: setScopedContext(key: "a", value: "1") {
            before: getScopedContext(key: "a")
            setInner: setScopedContext(key: "a", value: "2") {
              only: getScopedContext(key: "a")
            }
            after: getScopedContext(key: "a")
          }
          secondSetOuter: setScopedContext(key: "a", value: "3") {
            before: getScopedContext(key: "a")
            setInner: setScopedContext(key: "a", value: "4") {
              only: getScopedContext(key: "a")
            }
            after: getScopedContext(key: "a")
          }
          after: getScopedContext(key: "a")
        }
      |

      expected = {
        'before' => nil,
        'firstSetOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'secondSetOuter' => {
          'before' => '3',
          'setInner' => {
            'only' => '4',
          },
          'after' => '3',
        },
        'after' => nil,
      }
      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "can be set and does not leak to sibling fields when all resolvers are lazy values" do
      query_str = %|
        {
          before: getScopedContext(key: "a", lazy: true)
          setOuter: setScopedContext(key: "a", value: "1", lazy: true) {
            before: getScopedContext(key: "a", lazy: true)
            setInner: setScopedContext(key: "a", value: "2", lazy: true) {
              only: getScopedContext(key: "a", lazy: true)
            }
            after: getScopedContext(key: "a", lazy: true)
          }
          after: getScopedContext(key: "a", lazy: true)
        }
      |
      expected = {
        'before' => nil,
        'setOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'after' => nil,
      }

      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "can be set and does not leak to sibling fields when all get resolvers are lazy values" do
      query_str = %|
        {
          before: getScopedContext(key: "a", lazy: true)
          setOuter: setScopedContext(key: "a", value: "1") {
            before: getScopedContext(key: "a", lazy: true)
            setInner: setScopedContext(key: "a", value: "2") {
              only: getScopedContext(key: "a", lazy: true)
            }
            after: getScopedContext(key: "a", lazy: true)
          }
          after: getScopedContext(key: "a", lazy: true)
        }
      |
      expected = {
        'before' => nil,
        'setOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'after' => nil,
      }

      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "can be set and does not leak to sibling fields when all set resolvers are lazy values" do
      query_str = %|
        {
          before: getScopedContext(key: "a")
          setOuter: setScopedContext(key: "a", value: "1", lazy: true) {
            before: getScopedContext(key: "a")
            setInner: setScopedContext(key: "a", value: "2", lazy: true) {
              only: getScopedContext(key: "a")
            }
            after: getScopedContext(key: "a")
          }
          after: getScopedContext(key: "a")
        }
      |
      expected = {
        'before' => nil,
        'setOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'after' => nil,
      }

      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "always retrieves a scoped context value if set" do
      context = GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil, object: nil)
      expected_key = :a
      expected_value = :test

      assert_equal(nil, context[expected_key])
      assert_equal({}, context.to_h)
      refute(context.key?(expected_key))
      assert_raises(KeyError) { context.fetch(expected_key) }
      assert_nil(context.fetch(expected_key, nil))
      assert_nil(context.dig(expected_key)) if RUBY_VERSION >= '2.3.0'

      context.scoped_merge!(expected_key => nil)
      context[expected_key] = expected_value

      assert_nil(context[expected_key])
      assert_equal({ expected_key => nil }, context.to_h)
      assert(context.key?(expected_key))
      assert_nil(context.fetch(expected_key))
      assert_nil(context.dig(expected_key)) if RUBY_VERSION >= '2.3.0'

      context.scoped_context = {}

      assert_equal(expected_value, context[expected_key])
      assert_equal({ expected_key => expected_value}, context.to_h)
      assert(context.key?(expected_key))
      assert_equal(expected_value, context.fetch(expected_key))
      assert_equal(expected_value, context.dig(expected_key)) if RUBY_VERSION >= '2.3.0'
    end
  end
end
