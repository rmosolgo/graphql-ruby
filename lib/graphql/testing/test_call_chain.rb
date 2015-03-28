# Normalizes call inputs. Can handle:
# @example Call name and arguments passed separately
#   GraphQL::TestCallChain.new("other_call", 1, 2)
# @example A call without arguments
#   GraphQL::TestCallChain.new("other_call")
# @example Call name and arguments passed as a string
#   GraphQL::TestCallChain.new("other_call(1, 2)")
# @example Calls passed together, as a string
#   GraphQL::TestCallChain.new("my_call(1).other_call(1,2)")
# @example Calls passed separately, as arrays
#   GraphQL::TestCallChain.new(["my_call", 1], ["other_call", 1,2])
class GraphQL::TestCallChain
  # the {GraphQL::Syntax::Call}s identified
  attr_reader :calls

  def initialize(name=nil, *args)
    if name.blank?
      call_strings = []
    elsif name.is_a?(String) && name["("]
      call_strings = name.split(".")
    elsif name.is_a?(Array)
      call_arrays = [name] + args
      call_strings = call_arrays.map { |ca| join_call(ca) }
    elsif name.is_a?(String)
      call_array = [name] + args
      call_strings = [join_call(call_array)]
    end
    @calls = call_strings.map {|c| GraphQL.parse(:call, c)}
  end

  private

  def join_call(call_array)
    name = call_array[0]
    args = call_array[1..-1] || []
    "#{name}(#{args.join(",")})"
  end
end