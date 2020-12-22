# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::Redis do
  class DataloaderRedisSchema < GraphQL::Schema
    class MockRedis
      DATA = {
        "l1" => [1,2,3],
        "l2" => [4,5],
        "k1" => "hello",
        "k2" => "goodbye",
      }

      attr_reader :log
      def initialize
        @log = []
      end

      def pipelined
        @new_log = []
        res = yield
        @log << @new_log
        @new_log = nil
        res
      end

      def scard(name)
        @new_log << [:scard, name]
        if (d = DATA[name])
          if d.is_a?(Array)
            d.size
          else
            raise "Invalid data type for #{name.inspect}"
          end
        else
          0
        end
      end

      def get(name)
        @new_log << [:get, name]
        if (d = DATA[name])
          if d.is_a?(String)
            d
          else
            raise "Invalid data type for #{name.inspect}"
          end
        else
          nil
        end
      end
    end

    MOCK_REDIS = MockRedis.new

    class Query < GraphQL::Schema::Object
      field :count_list, Integer, null: false do
        argument :name, String, required: true
      end

      def count_list(name:)
        GraphQL::Dataloader::Redis.load(MOCK_REDIS, [:scard, name])
      end

      field :get_string, String, null: true do
        argument :name, String, required: true
      end

      def get_string(name:)
        GraphQL::Dataloader::Redis.load(MOCK_REDIS, [:get, name])
      end
    end

    query(Query)
    use GraphQL::Dataloader
  end

  def exec_query(*args, **kwargs)
    DataloaderRedisSchema.execute(*args, **kwargs)
  end

  before do
    DataloaderRedisSchema::MOCK_REDIS.log.clear
  end

  it "dispatches to .pipeline and sends method calls" do
    res = exec_query <<-GRAPHQL
    {
      k1: getString(name: "k1")
      l1: countList(name: "l1")
      k2: getString(name: "k2")
      l5: countList(name: "l5")
      k3: getString(name: "k3")
    }
    GRAPHQL

    expected_log = [
      [
        [:get, "k1"],
        [:scard, "l1"],
        [:get, "k2"],
        [:scard, "l5"],
        [:get, "k3"]
      ]
    ]

    assert_equal expected_log, DataloaderRedisSchema::MOCK_REDIS.log

    expected_data = {
      "k1" => "hello",
      "l1" => 3,
      "k2" => "goodbye",
      "l5" => 0,
      "k3" => nil
    }
    assert_equal(expected_data, res["data"])
  end
end
