# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Schema::Member::StrictLoading do
    class BooksSchema < GraphQL::Schema
      class User < GraphQL::Schema::Object
        field :username, String
      end

      class Review < GraphQL::Schema::Object
        include GraphQL::Schema::Member::StrictLoading

        field :stars, Integer
        field :user, User, dataload_association: true
        field :direct_user, User, method: :user
      end

      class Book < GraphQL::Schema::Object
        include GraphQL::Schema::Member::StrictLoading
        field :title, String
        field :direct_author, "BooksSchema::Author", method: :author
        field :dataloaded_author, "BooksSchema::Author", dataload_association: :author
        field :reviews, [Review]
      end

      class Author < GraphQL::Schema::Object
        include GraphQL::Schema::Member::StrictLoading
        field :name, String
        field :books, [Book]
      end

      class Query < GraphQL::Schema::Object
        field :author, Author do
          argument :id, ID
        end

        def author(id:)
          ::Author.find(id)
        end

        field :books, [Book]

        def books
          ::Book.all
        end
      end

      query(Query)
      use GraphQL::Dataloader
    end

    it "raises when belongs-to associations are lazy-loaded" do
      err = assert_raises ActiveRecord::StrictLoadingViolationError do
        BooksSchema.execute("{ books { reviews { directUser { username } } } }")
      end
      expected_message = "`Review` is marked for strict_loading. The User association named `:user` cannot be lazily loaded."
      assert_equal expected_message, err.message

      err = assert_raises ActiveRecord::StrictLoadingViolationError do
        BooksSchema.execute("{ books { directAuthor { name } } }")
      end
      expected_message = "`Book` is marked for strict_loading. The Author association named `:author` cannot be lazily loaded."
      assert_equal expected_message, err.message
    end

    it "doesn't raise when using dataloader" do
      res = BooksSchema.execute("{ books { dataloadedAuthor { name } } }")
      assert_equal 25, res["data"]["books"].size

      assert BooksSchema.execute("{ books { reviews { user { username } } } }")
    end

    it "doesn't raise on has-many associations" do
      res = BooksSchema.execute("{ author(id: 1) { books { title } } }")
      assert_equal 9, res["data"]["author"]["books"].size

      res = BooksSchema.execute("{ author(id: 1) { books { reviews { stars } } } }")
      assert res.key?("data")
    end
  end
end
