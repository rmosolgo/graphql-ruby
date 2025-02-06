# frozen_string_literal: true
require "spec_helper"
require "open3"

if testing_rails?
  describe GraphQL::Tracing::PerfettoTrace do
    include PerfettoSnapshot
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
  end
end
