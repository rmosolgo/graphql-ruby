# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Lazy do
  include LazyHelpers

  describe "resolving" do
    it "calls value handlers" do
      res = run_query('{  int(value: 2, plus: 1) }')
      assert_equal 3, res["data"]["int"]
    end

    it 'calls concurrent handlers' do
      res = run_query('{  concurrentInt(value: 2, plus: 1) }')
      assert_equal 3, res['data']['concurrentInt']
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

        d: concurrentNestedSum(value: 1) {
          value
          concurrentNestedSum(value: 2) {
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
        "d"=>{"value"=>1, "concurrentNestedSum"=>{
          "value"=>3
        }}
      }

      assert_equal expected_data, res["data"]
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

      assert_equal(nil, res["data"])
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
      assert_equal expected_data, res["data"]

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
        d: concurrentNestedSum(value: 2) { value }
      }
      GRAPHQL

      # This odd, non-adding behavior is hacked into `#sync_lazy`
      assert_equal 101, res["data"]["a"]["value"]
      assert_equal 113, res["data"]["b"]["value"]
      assert_equal 102, res["data"]["c"]["value"]
      assert_equal 2, res["data"]["d"]["value"]
    end
  end

  describe "LazyMethodMap" do
    class SubWrapper < LazyHelpers::Wrapper; end

    let(:map) { GraphQL::Execution::Lazy::LazyMethodMap.new }

    it "finds methods for classes and subclasses" do
      map.set(LazyHelpers::Wrapper, :item, :exec)
      map.set(LazyHelpers::SumAll, :value, :exec)
      b = LazyHelpers::Wrapper.new(1)
      sub_b = LazyHelpers::Wrapper.new(2)
      s = LazyHelpers::SumAll.new(3)
      assert_equal(:item, map.get(b).value_method)
      assert_equal(:exec, map.get(b).exec_method)

      assert_equal(:item, map.get(sub_b).value_method)
      assert_equal(:exec, map.get(sub_b).exec_method)

      assert_equal(:value, map.get(s).value_method)
      assert_equal(:exec, map.get(s).exec_method)
    end
  end
end
