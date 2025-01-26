require "bundler/inline"

gemfile do
  gem "graphql", path: "~/code/graphql-ruby"
  gem "google-protobuf"
  gem "activerecord", require: "active_record"
  gem "sqlite3"
end

ActiveRecord::Base.establish_connection({ adapter: "sqlite3", database: "flamegraph.db" })

class Author < ActiveRecord::Base
  has_many :books
end

class User < ActiveRecord::Base
  has_many :reviews
end

class Book < ActiveRecord::Base
  has_many :reviews
  belongs_to :author
end

class Review < ActiveRecord::Base
  belongs_to :user
  belongs_to :book
end

if ENV["RESEED"]
  `rm flamegraph.db`

  ActiveRecord::Schema.define do
    self.verbose = false
    create_table :books do |t|
      t.string :title
      t.integer :author_id
    end

    create_table :reviews do |t|
      t.integer :stars
      t.integer :user_id
      t.integer :book_id
    end

    create_table :authors do |t|
      t.string :name
    end

    create_table :users do |t|
      t.string :username
    end
  end

  Author.destroy_all
  Book.destroy_all
  User.destroy_all
  Review.destroy_all

  data = [
    {
      author: "William Shakespeare",
      titles: [
        "A Midsummer Night's Dream",
        "The Merry Wives of Windsor",
        "Much Ado about Nothing",
        "Julius Caesar",
        "Hamlet",
        "King Lear",
        "Macbeth",
        "Romeo and Juliet",
        "Othello"
      ]
    },
    {
      author: "Beatrix Potter",
      titles: [
        "The Tale of Peter Rabbit",
        "The Tale of Squirrel Nutkin",
        "The Tailor of Gloucester",
        "The Tale of Benjamin Bunny",
        "The Tale of Two Bad Mice",
        "The Tale of Mrs. Tiggy-Winkle",
        "The Tale of The Pie and the Patty-Pan",
        "The Tale of Mr. Jeremy Fisher",
        "The Story of a Fierce Bad Rabbit",
      ]
    },
    {
      author: "Charles Dickens",
      titles: [
        "The Pickwick Papers",
        "Oliver Twist",
        "A Christmas Carol",
        "David Copperfield",
        "Little Dorrit 	",
        "A Tale of Two Cities",
        "Great Expectations",
      ]
    }
  ]

  data.each do |info|
    author = Author.create!(name: info[:author])
    info[:titles].each do |title|
      Book.create!(author: author, title: title)
    end
  end

  users = ["matz", "tenderlove", "dhh", "_why"].map { |un| User.create!(username: un) }

  possible_stars = [1,2,3,4,5]
  Book.all.each do |book|
    users.each do |user|
      Review.create!(book: book, user: user, stars: possible_stars.sample)
    end
  end
end



class FlamegraphSchema < GraphQL::Schema
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
    field :author, "FlamegraphSchema::Author"

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
end

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

FlamegraphSchema.execute(query_str) # warm up

perfetto = GraphQL::Perfetto.new
res = FlamegraphSchema.execute(query_str, context: { perfetto: perfetto }).to_h
perfetto.write

if res["errors"]
  pp res["errors"]
  raise "Unsuccessful"
else
  puts "Finished"
end
