# frozen_string_literal: true
require "spec_helper"
require "open3"

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

      class OtherBook < GraphQL::Dataloader::Source
        def fetch(books)
          author_ids = books.map(&:author_id).uniq
          book_ids = ::Book.select(:id).where(author_id: author_ids).where.not(id: books.map(&:id)).group(:author_id).maximum(:id)
          other_books = dataloader.with(Record, ::Book).load_all(book_ids.values)
          books.map { |b| other_books.find { |b2| b.author_id == b2.author_id } }
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
        field :other_book, Book
        def reviews
          object.reviews.limit(2)
        end

        def average_review
          dataloader.with(AverageReview).load(object)
        end

        def author
          dataloader.with(Record, ::Author).load(object.author_id)
        end

        def other_book
          dataloader.with(OtherBook).load(object)
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
      trace_with GraphQL::Tracing::PerfettoTrace, name_prefix: "PerfettoSchema::"
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
            otherBook { title }
          }
        }
      }
      GRAPHQL
      # warm up:
      PerfettoSchema.execute(query_str)

      res = PerfettoSchema.execute(query_str)
      if ENV["DUMP_PERFETTO"]
        res.context.query.current_trace.write(file: "perfetto.dump")
      end

      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      data = JSON.parse(json)


      check_snapshot(data, "example-rails-#{Rails::VERSION::MAJOR}-#{Rails::VERSION::MINOR}.json")
    end

    it "provides an error when google-protobuf isn't available" do
      stderr_and_stdout, _status = Open3.capture2e(%|ruby -e 'require "bundler/inline"; gemfile(true) { source("https://rubygems.org"); gem("graphql", path: "./") }; class MySchema < GraphQL::Schema; trace_with(GraphQL::Tracing::PerfettoTrace); end;'|)
      assert_includes stderr_and_stdout, "GraphQL::Tracing::PerfettoTrace can't be used because the `google-protobuf` gem wasn't available. Add it to your project, then try again."
    end

    def check_snapshot(data, snapshot_name)
      snapshot_path = "spec/graphql/tracing/perfetto_trace/#{snapshot_name}"

      if ENV["UPDATE_PERFETTO"]
        puts "Updating PerfettoTrace snapshot: #{snapshot_path.inspect}"
        snapshot_json = convert_to_snapshot(data)
        File.write(snapshot_path, JSON.pretty_generate(snapshot_json))
      elsif !File.exist?(snapshot_path)
        raise "Snapshot file not found: #{snapshot_path.inspect}"
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
          assert_equal snapshot_data.sub(" #1010", ""), data.sub(/ #\d+/, ""), "Match at #{path.join(".")}"
        end
      when Numeric
        assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
      when Hash
        assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
        assert_equal snapshot_data.keys.sort, data.keys.sort, "Match at #{path.join(".")}"
        snapshot_data.each do |k, v|
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

    def convert_to_snapshot(value)
      case value
      when String
        if value.match(/\D/).nil?
          "10101010101010"
        else
          value.sub(/ #\d+/, " #1010")
        end
      when Numeric
        101010101010
      when Array
        value.map { |v| convert_to_snapshot(v) }
      when Hash
        h2 = {}
        value.each do |k, v|
          h2[k] = convert_to_snapshot(v)
        end
        h2
      when true, false, nil
        value
      else
        raise ArgumentError, "Unexpected JSON value: #{value}"
      end
    end
  end
end
