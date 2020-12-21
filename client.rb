require 'pg'

conn = PG.connect(
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'postgres',
  dbname: 'postgres',
)

conn.exec( "SELECT * FROM student" ) do |result|
  p result
end
