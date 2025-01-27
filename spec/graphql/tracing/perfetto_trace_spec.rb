# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Tracing::PerfettoTrace do
    class PerfettoSchema < GraphQL::Schema
      class BaseObject < GraphQL::Schema::Object
      end

      class AverageReview < GraphQL::Dataloader::Source
        def fetch(books)
          averages = ::Book.joins(:reviews)
            .select("books.id, AVG(stars) as avg_review ")
            .group("books.id")

          books.map { |b| averages.find { |avg| avg.id == b.id }&.avg_review }
        end
      end

      class Record < GraphQL::Dataloader::Source
        def initialize(model)
          @model = model
        end

        def fetch(ids)
          records = @model.where(id: ids)
          ids.map { |id| records.find { |r| r.id == id }}
        end
      end

      class User < BaseObject
        field :username, String
      end
      class Review < BaseObject
        field :stars, Int
        field :user, User

        def user
          dataloader.with(Record, ::User).load(object.user_id)
        end
      end

      class Book < BaseObject
        field :title, String
        field :reviews, [Review]
        field :average_review, Float
        field :author, "PerfettoSchema::Author"

        def reviews
          object.reviews.limit(2)
        end

        def average_review
          dataloader.with(AverageReview).load(object)
        end

        def author
          dataloader.with(Record, ::Author).load(object.author_id)
        end
      end

      class Author < BaseObject
        field :name, String
        field :books, [Book]

        def books
          object.books.limit(2)
        end
      end
      class Query < BaseObject
        field :authors, [Author]

        def authors
          ::Author.all
        end
      end

      query(Query)
      use GraphQL::Dataloader, fiber_limit: 7
      trace_with GraphQL::Tracing::PerfettoTrace
    end

    it "traces fields, dataloader, and activesupport notifications" do
      query_str = <<-GRAPHQL
      {
        authors {
          name
          books {
            title
            reviews {
              stars
              user {
                username
              }
            }
            averageReview
            author {
              name
            }
          }
        }
      }
      GRAPHQL
      # warm up:
      PerfettoSchema.execute(query_str)

      res = PerfettoSchema.execute(query_str)
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      data = JSON.parse(json)

      check_snapshot(data, "example.json")

      if ENV["DUMP_PERFETTO"]
        res.context.query.current_trace.write(file: "perfetto.dump")
      end
    end

    def check_snapshot(data, snapshot_name)
      snapshot_path = "spec/graphql/tracing/perfetto_trace/#{snapshot_name}"
      if ENV["UPDATE_PERFETTO"]
        puts "Updating PerfettoTrace snapshot"
        File.write(snapshot_path, JSON.pretty_generate(data))
      else
        snapshot_data = JSON.parse(File.read(snapshot_path))
        deep_snap_match(snapshot_data, data, [])
      end
    end

    def deep_snap_match(snapshot_data, data, path)
      case snapshot_data
      when String
        if snapshot_data.match(/\D/).nil? && data.match(/\D/).nil?
          # Ok
        else
          assert_equal snapshot_data, data, "Match at #{path.join(".")}"
        end
      when Numeric
        assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
      when Hash
        assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
        d_keys = data.keys
        snapshot_data.each do |k, v|
          assert_includes d_keys, k, "Key match at #{path.join(".")}"
          deep_snap_match(v, data[k], path + [k])
        end
      when Array
        assert_equal(snapshot_data.class, data.class, "Match at #{path.join(".")}")
        snapshot_data.each_with_index do |snapshot_i, idx|
          data_i = data[idx]
          deep_snap_match(snapshot_i, data_i, path + [idx])
        end
      end
    end
  end
end
