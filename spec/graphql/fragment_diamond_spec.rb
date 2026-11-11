# frozen_string_literal: true
require "spec_helper"

describe "Queries whose fragments spread the same fragments repeatedly" do
  class FragmentDiamondSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :a, String
      field :b, String
      field :nested, Query
      field :probe, Query, extras: [:lookahead]

      def a
        "a"
      end

      def b
        "b"
      end

      def nested
        self
      end

      def probe(lookahead:)
        context[:probe] = [lookahead.selections.map(&:name), lookahead.selects?(:a), lookahead.selection(:a).selected?]
        self
      end
    end

    Root = Struct.new(:a, :b) do
      def nested
        self
      end
    end
    ROOT = Root.new("a", "b")

    module DependencySizes
      def on_document(node, parent)
        super
        operation = node.definitions.find { |d| d.is_a?(GraphQL::Language::Nodes::OperationDefinition) }
        context.query.context[:dependency_sizes] = dependencies[operation].size
      end
    end

    class FieldVisitCounter < GraphQL::Analysis::Analyzer
      def initialize(query)
        super
        @visits = 0
      end

      def on_enter_field(node, parent, visitor)
        @visits += 1 if node.name == "a"
      end

      def result
        @visits
      end
    end

    query(Query)
    use GraphQL::Execution::Next
    validate_timeout(nil)
  end

  # Each layer's two fragments both spread the next layer's two fragments,
  # so expanding every spread visits 2**(layers + 1) copies of the last layer.
  def diamond_query(layers, leaf: "a")
    fragments = (0...layers).flat_map do |k|
      next_spreads = "...A#{k + 1} ...B#{k + 1}"
      ["fragment A#{k} on Query { #{next_spreads} }", "fragment B#{k} on Query { #{next_spreads} }"]
    end
    fragments << "fragment A#{layers} on Query { #{leaf} }" << "fragment B#{layers} on Query { #{leaf} }"
    "query { ...A0 ...B0 }\n#{fragments.join("\n")}"
  end

  def elapsed
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  it "records each fragment dependency once" do
    layers = 16
    schema = Class.new(FragmentDiamondSchema) { validate_timeout(nil) }
    query = GraphQL::Query.new(schema, diamond_query(layers))
    validator = GraphQL::StaticValidation::Validator.new(schema: schema, rules: GraphQL::StaticValidation::ALL_RULES + [FragmentDiamondSchema::DependencySizes])
    assert_equal [], validator.validate(query)[:errors]
    assert_equal 2 * (layers + 1), query.context[:dependency_sizes]
  end

  it "visits each fragment's fields once per selection during analysis" do
    query = GraphQL::Query.new(FragmentDiamondSchema, diamond_query(16))
    visits = GraphQL::Analysis.analyze_query(query, [FragmentDiamondSchema::FieldVisitCounter]).first
    assert_equal 2, visits
  end

  it "still visits a repeated fragment again inside a different field" do
    query_str = "query { ...F nested { ...F } } fragment F on Query { a }"
    query = GraphQL::Query.new(FragmentDiamondSchema, query_str)
    assert_equal 2, GraphQL::Analysis.analyze_query(query, [FragmentDiamondSchema::FieldVisitCounter]).first
  end

  it "looks ahead through a deep diamond of fragments quickly" do
    query_str = diamond_query(20).sub("query { ...A0 ...B0 }", "query { probe { ...A0 ...B0 } }")
    result = nil
    time = elapsed { result = FragmentDiamondSchema.execute(query_str, root_value: FragmentDiamondSchema::ROOT) }
    assert_equal({ "probe" => { "a" => "a" } }, result.to_h["data"])
    assert_equal [[:a], true, true], result.context[:probe]
    assert_operator time, :<, 1.0
  end

  [:execute, :execute_next].each do |method_name|
    describe "with #{method_name}" do
      it "runs a deep diamond of fragments quickly" do
        result = nil
        time = elapsed { result = FragmentDiamondSchema.public_send(method_name, diamond_query(20), root_value: FragmentDiamondSchema::ROOT).to_h }
        assert_equal({ "a" => "a" }, result["data"])
        assert_operator time, :<, 1.0
      end

      it "returns the same data as without repeated spreads" do
        query_str = "query($skip: Boolean!) { ...F ...F ...G @skip(if: $skip) ...G } fragment F on Query { a } fragment G on Query { b }"
        [true, false].each do |skip|
          result = FragmentDiamondSchema.public_send(method_name, query_str, variables: { "skip" => skip }, root_value: FragmentDiamondSchema::ROOT).to_h
          assert_equal({ "a" => "a", "b" => "b" }, result["data"])
        end
        result = FragmentDiamondSchema.public_send(method_name, "{ ...G @skip(if: true) } fragment G on Query { b }", root_value: FragmentDiamondSchema::ROOT).to_h
        assert_equal({}, result["data"])
      end
    end
  end
end
