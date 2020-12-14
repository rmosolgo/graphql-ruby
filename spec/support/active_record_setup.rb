# frozen_string_literal: true
p ["DATABASE is", ENV["DATABASE"]]

if testing_rails?
  # Remove the old sqlite database
  `rm -f ./_test_.db`

  # platform helper
  def jruby?
    RUBY_ENGINE == 'jruby'
  end

  if jruby?
    ActiveRecord::Base.establish_connection(adapter: "jdbcsqlite3", database: "./_test_.db")
    SequelDB = Sequel.connect('jdbc:sqlite:./_test_.db')
  elsif ENV['DATABASE'] == 'POSTGRESQL'
    ActiveRecord::Base.establish_connection(
      adapter: "postgresql",
      username: "postgres",
      password: ENV["POSTGRES_PASSWORD"], # empty in development, populated for GH Actions
      database: "graphql_ruby_test"
    )
    SequelDB = Sequel.connect("postgres://postgres:#{ENV["POSTGRES_PASSWORD"]}@localhost:5432/graphql_ruby_test")
  else
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "./_test_.db")
    SequelDB = Sequel.sqlite("./_test_.db")
  end

  ActiveRecord::Schema.define do
    self.verbose = false
    create_table :bases, force: true do |t|
      t.column :name, :string
      t.column :planet, :string
      t.column :faction_id, :integer
    end

    create_table :foods, force: true do |t|
      t.column :name, :string
    end
  end
end
