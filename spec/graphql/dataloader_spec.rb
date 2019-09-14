# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Dataloader" do
  module DataloaderTest
    module Backend
      LOG = []
      DATA = {
        "b1" => { title: "Remembering", author_id: "a1" },
        "b2" => { title: "That Distant Land", author_id: "a1" },
        "b3" => { title: "Doggies", author_id: "a2" },
        "a1" => { name: "Wendell Berry" },
        "a2" => { name: "Sandra Boynton"},
      }

      def self.mget(keys)
        LOG << "MGET #{keys}"
        keys.map { |k| DATA[k] }
      end
    end

    class BackendLoader < GraphQL::Dataloader::Loader
      def self.load(ctx, id)
        super(ctx, nil, id)
      end

      def perform(ids)
        Backend.mget(ids)
      end
    end


    class Schema < GraphQL::Schema
      class Author < GraphQL::Schema::Object
        field :name, String, null: false
      end

      class Book < GraphQL::Schema::Object
        field :title, String, null: false
        field :author, Author, null: false

        def author
          BackendLoader.load(context, object[:author_id])
        end
      end

      class Query < GraphQL::Schema::Object
        field :book, Book, null: true do
          argument :id, ID, required: true
        end

        def book(id:)
          BackendLoader.load(@context, id)
        end
      end

      query(Query)
      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
      use GraphQL::Dataloader
    end
  end

  def exec_query(*args)
    DataloaderTest::Schema.execute(*args)
  end

  let(:log) { DataloaderTest::Backend::LOG }

  before do
    log.clear
  end


  it "batches requests" do
    res = exec_query('{
      b1: book(id: "b1") { title author { name } }
      b2: book(id: "b2") { title author { name } }
    }')

    assert_equal "Remembering", res["data"]["b1"]["title"]
    assert_equal "Wendell Berry", res["data"]["b1"]["author"]["name"]
    assert_equal "That Distant Land", res["data"]["b2"]["title"]
    assert_equal "Wendell Berry", res["data"]["b2"]["author"]["name"]
    assert_equal ['MGET ["b1", "b2"]', 'MGET ["a1"]'], log
  end
end
