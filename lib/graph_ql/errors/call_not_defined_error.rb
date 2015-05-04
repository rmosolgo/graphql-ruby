# Raised when call is sent to a {Node}, but that {Node} hasn't defined such a call.
#
# @example
#   class URLNode < GraphQL::Node
#     call :protocol, -> (prev_value) { prev_value.split("//")[0] }
#   end
#
#   # This would raise a CallNotDefinedError:
#   "website('http://google.com') {
#      url.scheme()
#    }"
#   # `scheme` isn't defined but `protocol` is!

class GraphQL::CallNotDefinedError < GraphQL::Error
  def initialize(node_class, call_name)
    message = "You tried to send call '#{call_name}' but it wasn't found. Defined calls are: #{node_class.calls.keys.join(", ")}"
    super(message)
  end
end