# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Lazy do
  include LazyHelpers

  describe "resolving" do
    it "calls value handlers" do
      res = run_query('{  int(value: 2, plus: 1) }')
      assert_equal 3, res["data"]["int"]
    end

    it "Works with Query.new" do
      query_str = '{ int(value: 2, plus: 1) }'
      query = GraphQL::Query.new(LazyHelpers::LazySchema, query_str)
      res =  query.result
      assert_equal 3, res["data"]["int"]
    end

    it "can do nested lazy values" do
      res = run_query %|
      {
        a: nestedSum(value: 3) {
          value
          nestedSum(value: 7) {
            value
            nestedSum(value: 1) {
              value
              nestedSum(value: -50) {
                value
              }
            }
          }
        }
        b: nestedSum(value: 2) {
          value
          nestedSum(value: 11) {
            value
            nestedSum(value: 2) {
              value
              nestedSum(value: -50) {
                value
              }
            }
          }
        }

        c: listSum(values: [1,2]) {
          nestedSum(value: 3) {
            value
          }
        }
      }
      |

      expected_data = {
        "a"=>{"value"=>14, "nestedSum"=>{
          "value"=>46,
          "nestedSum"=>{
            "value"=>95,
            "nestedSum"=>{"value"=>90}
          }
        }},
        "b"=>{"value"=>14, "nestedSum"=>{
          "value"=>46,
          "nestedSum"=>{
            "value"=>95,
            "nestedSum"=>{"value"=>90}
          }
        }},
        "c"=>[
          {"nestedSum"=>{"value"=>14}},
          {"nestedSum"=>{"value"=>14}}
        ],
      }

      assert_graphql_equal expected_data, res["data"]
    end

    [
      [1, 2, LazyHelpers::MAGIC_NUMBER_WITH_LAZY_AUTHORIZED_HOOK],
      [2, LazyHelpers::MAGIC_NUMBER_WITH_LAZY_AUTHORIZED_HOOK, 1],
      [LazyHelpers::MAGIC_NUMBER_WITH_LAZY_AUTHORIZED_HOOK, 1, 2],
    ].each do |ordered_values|
      it "resolves each field at one depth before proceeding to the next depth (using #{ordered_values})" do
        res = run_query <<-GRAPHQL, variables: { values: ordered_values }
        query($values: [Int!]!) {
          listSum(values: $values) {
            nestedSum(value: 3) {
              value
            }
          }
        }
        GRAPHQL

        # Even though magic number `44`'s `.authorized?` hook returns a lazy value,
        # these fields should be resolved together and return the same value.
        assert_equal 56, res["data"]["listSum"][0]["nestedSum"]["value"]
        assert_equal 56, res["data"]["listSum"][1]["nestedSum"]["value"]
        assert_equal 56, res["data"]["listSum"][2]["nestedSum"]["value"]
      end
    end

    it "Handles fields that return nil and batches lazy resultion across depths when possible" do
      values = [
        LazyHelpers::MAGIC_NUMBER_THAT_RETURNS_NIL,
        LazyHelpers::MAGIC_NUMBER_WITH_LAZY_AUTHORIZED_HOOK,
        1,
        2,
      ]

      res = run_query <<-GRAPHQL, variables: { values: values }
      query($values: [Int!]!) {
        listSum(values: $values) {
          nullableNestedSum(value: 3) {
            value
          }
        }
      }
      GRAPHQL

      values = res["data"]["listSum"].map { |s| s && s["nullableNestedSum"]["value"] }
      assert_equal [nil, 56, 56, 56], values
    end

    it "propagates nulls to the root" do
      res = run_query %|
      {
        nestedSum(value: 1) {
          value
          nestedSum(value: 2) {
            nestedSum(value: 13) {
              value
            }
          }
        }
      }|

      assert_nil(res["data"])
      assert_equal 1, res["errors"].length
    end

    it "propagates partial nulls" do
      res = run_query %|
      {
        nullableNestedSum(value: 1) {
          value
          nullableNestedSum(value: 2) {
            ns: nestedSum(value: 13) {
              value
            }
          }
        }
      }|

      expected_data = {
        "nullableNestedSum" => {
          "value" => 1,
          "nullableNestedSum" => nil,
        }
      }
      assert_equal(expected_data, res["data"])
      assert_equal 1, res["errors"].length
    end

    it "handles raised errors" do
      res = run_query %|
      {
        a: nullableNestedSum(value: 1) { value }
        b: nullableNestedSum(value: 13) { value }
        c: nullableNestedSum(value: 2) { value }
      }|

      expected_data = {
        "a" => { "value" => 3 },
        "b" => nil,
        "c" => { "value" => 3 },
      }
      assert_graphql_equal expected_data, res["data"]

      expected_errors = [{
        "message"=>"13 is unlucky",
        "locations"=>[{"line"=>4, "column"=>9}],
        "path"=>["b"],
      }]
      assert_equal expected_errors, res["errors"]
    end

    it "resolves mutation fields right away" do
      res = run_query %|
      {
        a: nestedSum(value: 2) { value }
        b: nestedSum(value: 4) { value }
        c: nestedSum(value: 6) { value }
      }|

      assert_equal [12, 12, 12], res["data"].values.map { |d| d["value"] }

      res = run_query %|
      mutation {
        a: nestedSum(value: 2) { value }
        b: nestedSum(value: 4) { value }
        c: nestedSum(value: 6) { value }
      }
      |

      assert_equal [2, 4, 6], res["data"].values.map { |d| d["value"] }
    end
  end

  describe "Schema#sync_lazy(object)" do
    it "Passes objects to that hook at runtime" do
      res = run_query <<-GRAPHQL
      {
        a: nullableNestedSum(value: 1001) { value }
        b: nullableNestedSum(value: 1013) { value }
        c: nullableNestedSum(value: 1002) { value }
      }
      GRAPHQL

      # This odd, non-adding behavior is hacked into `#sync_lazy`
      assert_equal 101, res["data"]["a"]["value"]
      assert_equal 113, res["data"]["b"]["value"]
      assert_equal 102, res["data"]["c"]["value"]
    end
  end

  describe "LazyMethodMap" do
    class SubWrapper < LazyHelpers::Wrapper; end

    let(:map) { GraphQL::Execution::Lazy::LazyMethodMap.new }

    it "finds methods for classes and subclasses" do
      map.set(LazyHelpers::Wrapper, :item)
      map.set(LazyHelpers::SumAll, :value)
      b = LazyHelpers::Wrapper.new(1)
      sub_b = LazyHelpers::Wrapper.new(2)
      s = LazyHelpers::SumAll.new(3)
      assert_equal(:item, map.get(b))
      assert_equal(:item, map.get(sub_b))
      assert_equal(:value, map.get(s))
    end
  end

  describe "Interface.resolve_type" do
    class LazyResolveTypeSchema < GraphQL::Schema
      class Loader
        LOG = []
        DATA = {
          1 => { versionable: 3 },
          2 => { versionable: 4 },
          3 => { foo: "foo" },
          4 => { bar: "bar" },
        }

        def initialize(loading_key)
          @loading_key = loading_key
          @loading_ids = Set.new
          @loaded = {}
        end

        def self.for(context, loading_key)
          l_cache = context[:loader_cache] ||= Hash.new { |h, k| h[k] = Loader.new(k) }
          l_cache[loading_key]
        end

        def load(id)
          @loading_ids.add(id)
          -> {
            resolve
            result = @loaded.fetch(id)
            if block_given?
              yield(result)
            else
              result
            end
          }
        end

        def resolve
          if @loading_ids.any?
            Loader::LOG << [@loading_key, @loading_ids.to_a]
            @loading_ids.to_a.each do |id|
              @loaded[id] = DATA[id]
            end
            @loading_ids.clear
          end
        end
      end

      module Version
        include GraphQL::Schema::Interface

        def self.resolve_type(obj, ctx)
          Loader.for(ctx, :versionable).load(obj[:versionable]) do |versionable|
            versionable[:foo] ? FooVersionable : BarVersionable
          end
        end
      end

      class FooVersionable < GraphQL::Schema::Object
        implements Version
        field :foo, String
      end

      class BarVersionable < GraphQL::Schema::Object
        implements Version
        field :bar, String
      end

      class VersionReference < GraphQL::Schema::Object
        field :version, Version

        def version
          Loader.for(context, :version).load(object[:version])
        end
      end
      class Query < GraphQL::Schema::Object
        field :version_references, [VersionReference]

        def version_references
          [{ version: 1 }, { version: 2 }]
        end
      end

      lazy_resolve(Proc, :call)
      query(Query)
      orphan_types FooVersionable, BarVersionable
    end

    it "resolves lazies efficiently" do
      LazyResolveTypeSchema::Loader::LOG.clear
      query_str = " {
        versionReferences {
          version {
            ... on FooVersionable { foo }
            ... on BarVersionable { bar }
          }
        }
      }"
      res = LazyResolveTypeSchema.execute(query_str)
      pp res.to_h
      expected_log = [

      ]
      assert_equal expected_log, LazyResolveTypeSchema::Loader::LOG
    end
  end
end
