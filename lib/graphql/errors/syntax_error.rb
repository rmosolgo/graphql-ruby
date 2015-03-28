# The query couldn't be parsed.
class GraphQL::SyntaxError < GraphQL::Error
  def initialize(line, col, string)
    lines = string.split("\n")
    super("Syntax Error at (#{line}, #{col}), check usage: #{string}")
  end
end