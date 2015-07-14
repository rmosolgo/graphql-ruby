require 'pp'
class GraphQL::Repl
  def initialize(schema)
    @schema = schema
  end

  def run
    puts "Starting a repl for schema (type 'quit' to exit)"
    while line = gets do
      if line == "quit\n"
        exit
      end
      execute_query(line)
    end
  end

  private

  def execute_query(query_string)
    begin
      query = GraphQL::Query.new(@schema, query_string)
      puts JSON.pretty_generate(query.result)
    rescue StandardError => err
      puts "Couldn't parse: #{err}\n\n" # #{err.backtrace.join("\n")}"
    end
  end
end
