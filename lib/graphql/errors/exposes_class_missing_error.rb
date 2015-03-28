# This means a node has declared that it wraps a certain class, but that class wasn't found.
#
# @example
#   class ReceiptNode < GraphQL::Node
#     exposes("Reciept")
#     # ^^ uh oh, typo! That class doesn't exist.
#   end
#
# It's raised by {GraphQL::Schema::SchemaValidation#validate}.
class GraphQL::ExposesClassMissingError < GraphQL::Error
  def initialize(node_class)
    super("#{node_class.name} exposes #{node_class.exposes_class_names.join(", ")}, but that class wasn't found.")
  end
end
