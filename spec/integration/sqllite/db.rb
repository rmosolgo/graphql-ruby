# frozen_string_literal: true
`rm -f ./_test_.db`
# Set up "Bases" in ActiveRecord

if jruby?
  ActiveRecord::Base.establish_connection(adapter: "jdbcsqlite3", database: "./_test_.db")
  Sequel.connect('jdbc:sqlite:./_test_.db')
else
  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "./_test_.db")
  Sequel.sqlite("./_test_.db")
end
