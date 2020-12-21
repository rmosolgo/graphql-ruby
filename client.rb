require 'pg'

# Output a table of current connections to the DB
conn = PG.connect( dbname: 'postgres' )
conn.exec( "SELECT * FROM student" ) do |result|
  p result
end
