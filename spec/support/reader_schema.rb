# In-memory database ✨
DB = Sequel.sqlite

DB.create_table :authors do
  primary_key :id
  String :name
end

DB.create_table :books do
  primary_key :id
  foreign_key :author_id, :authors
  String :name
end

DB.create_table :readers do
  primary_key :id
  String :name
end

DB.create_table :reads do
  foreign_key :reader_id, :readers
  foreign_key :book_id, :books
end

class Author < Sequel::Model
  one_to_many :books
end
class Book < Sequel::Model
  many_to_one :author
  many_to_many :readers, join_table: :reads
end
class Reader < Sequel::Model
  many_to_many :books, join_table: :reads
end
class Read < Sequel::Model
  many_to_one :book
  many_to_one :reader
end

Author.insert(name: "George RR Martin")
Author.insert(name: "JK Rowling")

10.times do |n|
  Book.insert(name: "Game of Thrones #{n}", author_id: 1)
  Book.insert(name: "Harry Potter #{n}", author_id: 2)
end

3.times do |n|
  reader = Reader.insert(name: "Reader #{n}")
  (n * 3).times do |i|
    book = Book.where(name: "Harry Potter #{i}").first
    book_2 = Book.where(name: "Game of Thrones #{i}").first

    Read.insert(reader_id: n, book_id: book[:id])
    Read.insert(reader_id: n, book_id: book_2[:id])
  end
end


# A logger that just exposes how many messages it has
# received (which is a proxy for # of queries run)
class CountLogger
  attr_reader :queries
  def initialize
    @queries = []
  end
  def info(message)
    queries << message
    puts "#{count}     > #{message}"
  end
  def error(message); end
  def count
    queries.count
  end
  def clear
    queries.clear
  end
end

DB.loggers << (COUNT_LOGGER = CountLogger.new)

def with_includes(relation, projections)
  include_keys = projections.keys.map(&:to_sym) & relation.associations
  p include_keys
  include_keys.any? ? relation.eager(*include_keys) : relation
end

AuthorType = GraphQL::ObjectType.define do
  name("Author")
  field :name, types.String
  field :books, -> { types[BookType] } do
    argument :first, types.Int
    resolve -> (obj, args, ctx) {
      if args["first"]
        books = obj.books_dataset.limit(args["first"])
      else
        books = obj.books
      end
      books
    }
  end
end

BookType = GraphQL::ObjectType.define do
  name("Book")
  field :name, types.String
  field :author, AuthorType
  field :readers, -> { types[ReaderType] }
end

ReaderType = GraphQL::ObjectType.define do
  name("Reader")
  field :name, types.String
  field :books, types[BookType] do
    argument :first, types.Int
    resolve -> (obj, args, ctx) {
      books = obj.books_dataset.eager(:author)
      if args["first"]
        books = obj.books_dataset.limit(args["first"])
      end
      books
    }
  end
end

ReaderQueryType = GraphQL::ObjectType.define do
  name "Query"
  field :currentReader, ReaderType do
    resolve -> (obj, args, ctx) {
         # with_includes(Reader, ctx.projections)[id: 2]
         Reader[id: 2]
    }
  end
end

ReaderSchema = GraphQL::Schema.new(query: ReaderQueryType)
