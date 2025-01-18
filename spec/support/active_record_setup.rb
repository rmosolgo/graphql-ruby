# frozen_string_literal: true
if testing_rails?
  # Remove the old sqlite database
  puts "Removing _test_.db"
  `rm -f ./_test_.db`

  if ActiveRecord.respond_to?(:async_query_executor=) # Rails 7.1+
    ActiveRecord.async_query_executor ||= :global_thread_pool
  end

  if ENV['DATABASE'] == 'POSTGRESQL'
    ar_connection_options = {
      host: "localhost",
      adapter: "postgresql",
      username: "postgres",
      password: ENV["PGPASSWORD"], # empty in development, populated for GH Actions
      database: "graphql_ruby_test",
    }
    ActiveRecord::Base.establish_connection(ar_connection_options.merge(
      database: "postgres"
    ))
    databases = ActiveRecord::Base.connection.execute("select datname from pg_database;")
    test_db = databases.find { |d| d["datname"] == "graphql_ruby_test" }
    if test_db.nil?
      ActiveRecord::Base.connection.execute("create database graphql_ruby_test;")
    end

    ActiveRecord::Base.configurations = {
      starwars: ar_connection_options,
      starwars_replica: ar_connection_options,
    }

    SequelDB = Sequel.connect("postgres://postgres:#{ENV["PGPASSWORD"]}@localhost:5432/graphql_ruby_test")
  else
    ActiveRecord::Base.configurations = {
      starwars: { adapter: "sqlite3", database: "./_test_.db" },
      starwars_replica: { adapter: "sqlite3", database: "./_test_.db" },
    }
    SequelDB = Sequel.sqlite("./_test_.db")
  end

  ActiveRecord::Base.establish_connection(:starwars)
  ActiveRecord::Schema.define do
    self.verbose = !!ENV["GITHUB_ACTIONS"]
    create_table :bases, force: true do |t|
      t.column :name, :string
      t.column :planet, :string
      t.column :faction_id, :integer
    end

    create_table :foods, force: true do |t|
      t.column :name, :string
    end

    create_table :things, force: true do |t|
      t.string :name
      t.integer :other_thing_id
    end

    create_table :bands, force: true do |t|
      t.string :name
      t.integer :genre
    end

    create_table :albums, force: true do |t|
      t.string :name
      t.integer :band_id
    end
  end

  class Food < ActiveRecord::Base
    include GlobalID::Identification
  end

  class Album < ActiveRecord::Base
    belongs_to :band
  end
  class Band < ActiveRecord::Base
    has_many :albums
    enum :genre, [:rock, :country]
  end

  class AlternativeBand < Band
    self.table_name = :bands
    self.primary_key = :name
  end

  v = Band.create!(id: 1, name: "Vulfpeck", genre: :rock)
  t = Band.create!(id: 2, name: "Tom's Story", genre: :rock)
  c = Band.create!(id: 3, name: "Chon", genre: :rock)
  w = Band.create!(id: 4, name: "Wilco", genre: :country)

  v.albums.create!(id: 1, name: "Mit Peck")
  v.albums.create!(id: 2, name: "My First Car")
  t.albums.create!(id: 3, name: "Tom's Story")
  c.albums.create!(id: 4, name: "Homey")
  c.albums.create!(id: 5, name: "Chon")
  w.albums.create!(id: 6, name: "Summerteeth")
end
