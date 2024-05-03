# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::AsyncDataloader do
  class RailsAsyncSchema < GraphQL::Schema
    class BaseSource < GraphQL::Dataloader::Source
      def fetch(ids)
        bases = StarWars::Base.where(id: ids)
        ids.map { |id| bases.find { |b| b.id == id } }
      end
    end

    class SelfSource < GraphQL::Dataloader::Source
      def fetch(ids)
        ids
      end
    end

    class Query < GraphQL::Schema::Object
      field :base_name, String do
        argument :id, Int
      end

      def base_name(id:)
        base = dataloader.with(BaseSource).load(id)
        base&.name
      end

      field :self, Query

      field :inline_base_name, String do
        argument :id, Int
      end

      def inline_base_name(id:)
        StarWars::Base.where(id: id).first&.name
      end

      def self
        dataloader.with(SelfSource).load(:self)
      end
    end

    query(Query)
    use GraphQL::Dataloader::AsyncDataloader
  end

  before {
    @prev_isolation_level = ActiveSupport::IsolatedExecutionState.isolation_level
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveSupport::IsolatedExecutionState.isolation_level = :fiber
  }

  after {
    ActiveSupport::IsolatedExecutionState.isolation_level = @prev_isolation_level
  }

  it "cleans up database connections" do
    query_str = "{
      b1: baseName(id: 1) b2: baseName(id: 2)
      ib1: inlineBaseName(id: 1)
      self {
        b3: baseName(id: 3)
        self {
          b4: baseName(id: 4)
          ib2: inlineBaseName(id: 2)
        }
      }
    }"
    res = RailsAsyncSchema.execute(query_str)
    assert_equal({
      "b1" => "Yavin", "b2" => "Echo Base", "ib1" => "Yavin",
      "self" => {
        "b3" => "Secret Hideout",
        "self" => { "b4" => "Death Star", "ib2" => "Echo Base" }
      }
    }, res["data"])

    RailsAsyncSchema.execute(query_str)
    RailsAsyncSchema.execute(query_str)

    assert_equal 1, ActiveRecord::Base.connection_pool.connections.size
  end
end
