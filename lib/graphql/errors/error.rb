# @abstract
# Base class for all errors, so you can rescue from all graphql errors at once.
#
# @example Rescue from any GraphQL error
#   begin
#     GraphQL::Query.new(query_string, context: context)
#   rescue GraphQL::Error => err
#     puts "Something went wrong during the query: #{err}"
#   end
class GraphQL::Error < RuntimeError
  def initialize(message)
    super("#{message}\n\nMore info: #{link_to_documentation}")
  end

  private

  def link_to_documentation
    own_name = self.class.name.split("::").last
    "http://www.rubydoc.info/gems/graphql/#{GraphQL::VERSION}/GraphQL/#{own_name}"
  end
end