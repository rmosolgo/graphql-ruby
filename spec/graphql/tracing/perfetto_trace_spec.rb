# frozen_string_literal: true
require "spec_helper"
require "open3"

if testing_rails?
  describe GraphQL::Tracing::PerfettoTrace do
    include PerfettoSnapshot

    def trace_includes?(json_str, test_str)
      json_str.include?(Base64.encode64(test_str).strip) ||
        json_str.include?(test_str)
    end

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
          other_books = dataloader.with(GraphQL::Dataloader::ActiveRecordSource, ::Book).load_all(book_ids.values)
          books.map { |b| other_books.find { |b2| b.author_id == b2.author_id } }
        end
      end
      class Authorized < GraphQL::Dataloader::Source
        def fetch(objs)
          objs.map { true }
        end
      end

      class User < BaseObject
        field :username, String
      end
      class Review < BaseObject
        field :stars, Int
        field :user, User

        def self.authorized?(obj, ctx)
          ctx.dataloader.with(Authorized).load(obj)
        end

        def user
          dataload_record(::User, object[:user_id])
        end
      end

      class Book < BaseObject
        field :title, String
        field :reviews, [Review]
        field :average_review, Float
        field :author, "PerfettoSchema::Author"
        field :other_book, Book
        def reviews
          object.reviews.limit(2).map { |r| { stars: r.stars, user_id: r.user } }
        end

        def average_review
          dataload(AverageReview, object)
        end

        def author
          dataload_association(:author)
        end

        def other_book
          dataload(OtherBook, object)
        end
      end

      class Author < BaseObject
        field :name, String
        field :books, [Book]

        def books
          object.books.limit(2)
        end
      end

      class Thing < GraphQL::Schema::Union
        possible_types(Author, Book)
      end
      class Query < BaseObject
        field :authors, [Author]

        def authors
          ::Author.all
        end

        field :thing, Thing do
          argument :id, ID
        end

        def thing(id:)
          model_name, db_id = id.split("-")
          dataload_record(Object.const_get(model_name), db_id)
        end

        field :crash, Int
        def crash
          raise "Crash the query"
        end

        class SecretInput < GraphQL::Schema::InputObject
          argument :password, String
        end

        class SecretThing < GraphQL::Schema::Object
          field :greeting, String
        end

        field :secret_field, SecretThing do
          argument :cipher, String, required: false
          argument :password, String, required: false
          argument :input, [[SecretInput]], required: false
        end

        def secret_field(cipher: nil, password: nil, input: nil)
          {
            greeting: "Hello!",
            cipher: cipher || "FALLBACK_CIPHER",
            anon: Class.new.new,
            password: password || (input ? input[0][0][:password] : "FALLBACK_PASSWORD"),
          }
        end
      end

      query(Query)
      use GraphQL::Dataloader, fiber_limit: 7
      trace_with GraphQL::Tracing::PerfettoTrace

      def self.resolve_type(type, obj, ctx)
        self.const_get(obj.class.name)
      end

      def self.detailed_trace?(q)
        true
      end
    end

    it "traces fields, dataloader, and activesupport notifications" do
      query_str = <<-GRAPHQL
      query GetStuff($thingId: ID!) {
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

        t5: thing(id: $thingId) { ... on Book { title } ... on Author { name }}
      }
      GRAPHQL
      # warm up:
      PerfettoSchema.execute(query_str, variables: { thingId: "Book-#{::Book.first.id}" })

      res = PerfettoSchema.execute(query_str, variables: { thingId: "Book-#{::Book.first.id}" })
      if ENV["DUMP_PERFETTO"]
        res.context.query.current_trace.write(file: "perfetto.dump")
      end

      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      data = JSON.parse(json)


      check_snapshot(data, "example-rails-#{Rails::VERSION::MAJOR}-#{Rails::VERSION::MINOR}.json")
    end

    it "replaces nil class name with (anonymous)" do
      query_str = 'query getStuff { secretField { greeting } }'
      res = PerfettoSchema.execute(query_str)
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert trace_includes?(json, "(anonymous)")
    end

    it "filters params with Rails.application.config.filter_parameters" do
      query_str = 'query getStuff { secretField(cipher: "abcdef") { greeting } }'
      res = PerfettoSchema.execute(query_str)
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert trace_includes?(json, "abcdef")
      refute trace_includes?(json, "FILTERED")

      if Rails.application.present?
        prev_fp = Rails.application.config.filter_parameters
        Rails.application.config.filter_parameters = ["ciph"]
      else
        Rails.application = OpenStruct.new(config: OpenStruct.new(filter_parameters: ["ciph"]))
      end
      res = PerfettoSchema.execute(query_str)
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      refute trace_includes?(json, "abcdef")
      assert trace_includes?(json, "FILTERED")
    ensure
      if prev_fp
        Rails.application.config.filter_parameters = prev_fp
      else
        Rails.application = nil
      end
    end

    it "filters params with ActiveSupport" do
      query_str = 'query getStuff { secretField(cipher: "abcdef") { greeting } }'
      res = PerfettoSchema.execute(query_str)
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert trace_includes?(json, "abcdef")
      refute trace_includes?(json, "FILTERED")

      query_str = 'query getStuff { secretField(cipher: "abcdef") { greeting } }'
      res = PerfettoSchema.execute(query_str)
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert trace_includes?(json, "abcdef")
      refute trace_includes?(json, "FILTERED")

      if ActiveSupport.respond_to?(:filter_parameters=)
        begin
          prev_fp = ActiveSupport.filter_parameters
          ActiveSupport.filter_parameters = ["cipher"]
          res = PerfettoSchema.execute(query_str)
          json = res.context.query.current_trace.write(file: nil, debug_json: true)
          refute trace_includes?(json, "abcdef")
          assert trace_includes?(json, "[FILTERED]")

          ActiveSupport.filter_parameters = ["password"]
          res = PerfettoSchema.execute('query getStuff { secretField(input: [[{ password: "jklmn" }]]) { greeting } }')
          json = res.context.query.current_trace.write(file: nil, debug_json: true)
          assert trace_includes?(json, "password"), "Name is retained"
          refute trace_includes?(json, "jklmn"), "Value is removed"
          assert_includes json, "[FILTERED]"
        ensure
          ActiveSupport.filter_parameters = prev_fp
        end
      end
    end

    it "filters params without ActiveSupport" do
      query_str = 'query getStuff { secretField(password: "qrstuv") { greeting } }'
      res = PerfettoSchema.execute(query_str, context: { detailed_trace_filter: GraphQL::Tracing::PerfettoTrace::ArgumentsFilter.new })
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert trace_includes?(json, "FILTERED"), "The replacement string is present"
      assert trace_includes?(json, "FALLBACK_CIPHER"), "Unfiltered values are present"
      refute trace_includes?(json, "qrstuv"), "The password is obscured"

      query_str = 'query getStuff { secretField(input: [[{ password: "lmnop" }]]) { greeting } }'
      res = PerfettoSchema.execute(query_str, context: { detailed_trace_filter: GraphQL::Tracing::PerfettoTrace::ArgumentsFilter.new })
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert trace_includes?(json, "password"), "Name is retained"
      refute trace_includes?(json, "lmnop"), "The password is obscured"
      assert trace_includes?(json, "[FILTERED]"), "The replacement string is present"
    end

    it "provides an error when google-protobuf isn't available" do
      stderr_and_stdout, _status = Open3.capture2e(%|ruby -e 'require "bundler/inline"; gemfile(true) { source("https://rubygems.org"); gem("graphql", path: "./") }; class MySchema < GraphQL::Schema; trace_with(GraphQL::Tracing::PerfettoTrace); end;'|)
      assert_includes stderr_and_stdout, "GraphQL::Tracing::PerfettoTrace can't be used because the `google-protobuf` gem wasn't available. Add it to your project, then try again."
    end

    it "doesn't leave AS::N subscriptions behind" do
      refute ActiveSupport::Notifications.notifier.listening?("event.nonsense")
      _trace_instance = PerfettoSchema.new_trace
      refute ActiveSupport::Notifications.notifier.listening?("event.nonsense")

      assert_raises do
        PerfettoSchema.execute("{ crash }")
      end
      refute ActiveSupport::Notifications.notifier.listening?("event.nonsense")
    end

    it "doesn't create DebugAnnotations when `debug: false` or `detailed_trace_debug: false`" do
      res = PerfettoSchema.execute("{ authors { name } }")
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert_includes json, "debugAnnotations", "it includes them by default"

      res = PerfettoSchema.execute("{ authors { name } }", context: { detailed_trace_debug: false })
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert_nil json["debugAnnotations"], "doesn't write debug annotations with detailed_trace_debug: false"

      # Ususally this would be `use DetailedTrace, debug: false`
      PerfettoSchema.detailed_trace = GraphQL::Tracing::DetailedTrace.new(storage: nil, trace_mode: nil, debug: false)
      res = PerfettoSchema.execute("{ authors { name } }")
      assert_equal 4, res["data"]["authors"].size
      json = res.context.query.current_trace.write(file: nil, debug_json: true)
      assert_nil json["debugAnnotations"], "doesn't write them when top-level setting is false "
    ensure
      PerfettoSchema.detailed_trace = nil
    end
  end
end
