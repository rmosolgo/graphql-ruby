require "spec_helper"

class ArrayCollector
  attr_reader :patches
  def initialize(logger: nil)
    @patches = []
    @logger = logger
  end

  def patch(path:, value:)
    @logger && @logger.push({path: path, value: value})
    patches << {path: path, value: value}
  end

  def merged_result
    patches.each_with_object({}) do |patch, result|
      path = patch[:path]
      patch_value = patch[:value]
      target_key = path.last
      if target_key.nil? # first patch
        result.merge!(patch_value)
      else
        target_hash = result
        path_to_hash = path[0..-2]
        # Move down the response, adding hashes if the key isn't found
        path_to_hash.each do |part|
          target_hash = target_hash[part] ||= {}
        end
        target_hash[target_key] = patch_value
      end
    end
  end
end

describe GraphQL::Execution::DeferredExecution do
  before do
    @prev_execution_strategy = DummySchema.query_execution_strategy
    DummySchema.query_execution_strategy = GraphQL::Execution::DeferredExecution
  end

  after do
    DummySchema.query_execution_strategy = @prev_execution_strategy
  end

  let(:collector) { ArrayCollector.new }
  let(:result) {
    DummySchema.execute(query_string, context: {collector: collector})
  }

  describe "@defer-ed fields" do
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
          origin @defer
          cheeseSource: source @defer
        }
      }
    |}

    it "emits them later" do
      result
      assert_equal 3, collector.patches.length

      expected_first_patch = {
        path: [],
        value: {"data" => {
          "cheese" => {
            "id" => 1,
            "flavor" => "Brie",
          }
        }}
      }
      expected_second_patch = {
        path: ["data", "cheese", "origin"],
        value: "France"
      }
      expected_third_patch = {
        path: ["data", "cheese", "cheeseSource"],
        value: "COW",
      }

      assert_equal(expected_first_patch, collector.patches[0])
      assert_equal(expected_second_patch, collector.patches[1])
      assert_equal(expected_third_patch, collector.patches[2])
    end

    it "can be reassembled into a single response" do
      result
      expected_data = {
        "cheese" => {
          "id" => 1,
          "flavor" => "Brie",
          "origin" => "France",
          "cheeseSource" => "COW",
        }
      }
      assert_equal({"data" => expected_data }, collector.merged_result)
    end
  end

  describe "nested @defers" do
    let(:query_string) {%|
      {
        cheese(id: 1) @defer {
          id
          flavor
          origin @defer
        }
      }
    |}

    it "patches the object, then the field" do
      result
      assert_equal 3, collector.patches.length

      assert_equal([], collector.patches[0][:path])
      assert_equal({ "data" => {} }, collector.patches[0][:value])

      assert_equal(["data", "cheese"], collector.patches[1][:path])
      assert_equal({"id" => 1, "flavor" => "Brie"}, collector.patches[1][:value])

      assert_equal(["data", "cheese", "origin"], collector.patches[2][:path])
      assert_equal("France", collector.patches[2][:value])
    end
  end

  describe "@defer-ing a list" do
    let(:query_string) {%|
      {
        cheeses @defer {
          id
          chzFlav: flavor @defer
          similarCheese(source: COW) {
            id
            flavor @defer
          }
        }
      }
      |}
    it "patches the whole list, then the member fields" do
      result
      assert_equal 8, collector.patches.length
      expected_patches = [
        {
          path: [],
          value: { "data" => {} }
        },
        {
          path: ["data", "cheeses"],
          value: [
            {"id"=>1, "similarCheese"=>{"id"=>1}},
            {"id"=>2, "similarCheese"=>{"id"=>1}},
            {"id"=>3, "similarCheese"=>{"id"=>1}}
          ]
        },
        {
          path: ["data", "cheeses", 0, "chzFlav"],
          value: "Brie"
        },
        {
          path: ["data", "cheeses", 0, "similarCheese", "flavor"],
          value: "Brie"
        },
        {
          path: ["data", "cheeses", 1, "chzFlav"],
          value: "Gouda"
        },
        {
          path: ["data", "cheeses", 1, "similarCheese", "flavor"],
          value: "Brie"
        },
        {
          path: ["data", "cheeses", 2, "chzFlav"],
          value: "Manchego"
        },
        {
          path: ["data", "cheeses", 2, "similarCheese", "flavor"],
          value: "Brie"
        },
      ]

      assert_equal(expected_patches, collector.patches)
      expected_data = {
        "cheeses" => [
          {
            "id"=>1,
            "chzFlav"=>"Brie",
            "similarCheese"=>{"id"=>1, "flavor"=>"Brie"}
          },
          {
            "id"=>2,
            "chzFlav"=>"Gouda",
            "similarCheese"=>{"id"=>1, "flavor"=>"Brie"}
          },
          {
            "id"=>3,
            "chzFlav"=>"Manchego",
            "similarCheese"=>{"id"=>1, "flavor"=>"Brie"}
          }
        ]
      }
      assert_equal(expected_data, collector.merged_result["data"])
    end
  end

  describe "@defer with errors" do
    describe "when errors are handled" do
      let(:query_string) {%|
        {
          error1: executionError
          error2: executionError @defer
          error3: executionError @defer
        }
      |}
      it "patches errors to the errors key" do
        result
        assert_equal(3, collector.patches.length)
        assert_equal([], collector.patches[0][:path])
        assert_equal([{"message" => "There was an execution error", "locations"=>[{"line"=>3, "column"=>11}]}], collector.patches[0][:value]["errors"])
        assert_equal({"error1"=>nil}, collector.patches[0][:value]["data"])
        assert_equal(["errors", 1], collector.patches[1][:path])
        assert_equal({"message"=>"There was an execution error", "locations"=>[{"line"=>4, "column"=>11}]}, collector.patches[1][:value])
        assert_equal(["errors", 2], collector.patches[2][:path])
        assert_equal({"message"=>"There was an execution error", "locations"=>[{"line"=>5, "column"=>11}]}, collector.patches[2][:value])
      end
    end

    describe "when errors are raised" do
      let(:query_string) {%|
        {
          error
          cheese(id: 1) @defer { id }
        }
      |}

      it "dies altogether" do
        assert_raises(RuntimeError) { result }
        assert_equal 0, collector.patches.length
      end
    end
  end

  describe "@stream-ed fields" do
    let(:query_string) {%|
    {
      cheeses @stream {
        id
      }
    }
    |}

    it "pushes an empty list, then each item" do
      result

      assert_equal(4, collector.patches.length)
      assert_equal([], collector.patches[0][:path])
      assert_equal({"data" => { "cheeses" => [] } }, collector.patches[0][:value])
      assert_equal(["data", "cheeses", 0], collector.patches[1][:path])
      assert_equal({"id"=>1}, collector.patches[1][:value])
      assert_equal(["data", "cheeses", 1], collector.patches[2][:path])
      assert_equal({"id"=>2}, collector.patches[2][:value])
      assert_equal(["data", "cheeses", 2], collector.patches[3][:path])
      assert_equal({"id"=>3}, collector.patches[3][:value])
    end

    describe "lists inside @streamed lists" do
      let(:query_string) {%|
      {
        milks @stream {
          flavors
        }
      }
      |}

      it "streams the outer list but sends the inner list wholesale" do
        result
        # One with an empty list, then 2 patches
        assert_equal(3, collector.patches.length)
      end
    end

    describe "nested defers" do
      let(:query_string) {%|
      {
        cheeses @stream {
          id
          flavor @defer
        }
      }
      |}

      it "pushes them after streaming items" do
        result

        # - 1 empty-list + (1 id + 1 flavor) * list-items
        assert_equal(7, collector.patches.length)
        assert_equal([], collector.patches[0][:path])
        assert_equal({"data" => { "cheeses" => [] } }, collector.patches[0][:value])
        assert_equal(["data", "cheeses", 0], collector.patches[1][:path])
        assert_equal({"id"=>1}, collector.patches[1][:value])
        assert_equal(["data", "cheeses", 0, "flavor"], collector.patches[2][:path])
        assert_equal("Brie", collector.patches[2][:value])
        assert_equal(["data", "cheeses", 1], collector.patches[3][:path])
        assert_equal({"id"=>2}, collector.patches[3][:value])
        assert_equal(["data", "cheeses", 1, "flavor"], collector.patches[4][:path])
        assert_equal("Gouda", collector.patches[4][:value])
        assert_equal(["data", "cheeses", 2], collector.patches[5][:path])
        assert_equal({"id"=>3}, collector.patches[5][:value])
        assert_equal(["data", "cheeses", 2, "flavor"], collector.patches[6][:path])
        assert_equal("Manchego", collector.patches[6][:value])
      end
    end

    describe "lazy enumerators" do
      let(:event_log) { [] }
      let(:collector) { ArrayCollector.new(logger: event_log) }
      let(:lazy_schema) {
        logger = event_log
        query_type = GraphQL::ObjectType.define do
          name("Query")
          field :lazyInts, types[types.Int] do
            argument :items, !types.Int
            resolve -> (obj, args, ctx) {
              Enumerator.new do |yielder|
                i = 0
                while i < args[:items]
                  logger.push({yield: i})
                  yielder.yield(i)
                  i += 1
                end
              end
            }
          end
        end
        schema = GraphQL::Schema.new(query: query_type)
        schema.query_execution_strategy = GraphQL::Execution::DeferredExecution
        schema
      }

      let(:result) {
        lazy_schema.execute(query_string, context: {collector: collector})
      }

      let(:query_string) {%|
      {
        lazyInts(items: 4) @stream
      }
      |}

      it "evaluates them lazily" do
        result
        # The goal here is that the enumerator is called
        # _after_ each patch, not all once ahead of time.
        expected_events = [
          {path: [], value: {"data"=>{"lazyInts"=>[]}}},
          {yield: 0},
          {path: ["data", "lazyInts", 0], value: 0},
          {yield: 1},
          {path: ["data", "lazyInts", 1], value: 1},
          {yield: 2},
          {path: ["data", "lazyInts", 2], value: 2},
          {yield: 3},
          {path: ["data", "lazyInts", 3], value: 3}
        ]
        assert_equal expected_events, event_log
      end
    end
  end
end
