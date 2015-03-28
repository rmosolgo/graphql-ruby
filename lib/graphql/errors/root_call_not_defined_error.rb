# The root call of this query isn't in the schema.
class GraphQL::RootCallNotDefinedError < GraphQL::Error
  def initialize(name)
    super("Call '#{name}' was requested but was not found. Defined calls are: #{SCHEMA.call_names}")
  end
end