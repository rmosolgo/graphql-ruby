# {TestCall} provides an interface for testing calls that you have defined.
#
# Usually, you get a {TestCall} from {RootCall.test}.
#
# You can test calls in your system by:
#
# - Testing their return values
# - Testing them with different contexts, using {#with_context}
# - Testing them with different arguments, by passing them to {#execute} or {#with_arguments}
#
# @example Testing a call's return value
#   # Given this node & call:
#   class RestaurantNode < GraphQL::Node
#     field.string(:name)
#   end
#
#   class RenameRestaurantCall < GraphQL::RootCall
#     returns(:restaruant)
#     argument.number(:id)
#     argument.string(:new_name)
#
#     def execute!(id, new_name)
#       restaurant = Restaurant.find(id)
#       if context[:user].admin?
#         restaurant.update_attributes(name: new_name)
#       else
#         # todo: how to handle errors in a GraphQL system?
#       end
#
#       restaurant
#     end
#   end
#
#   # We could test its returns:
#   restaurant = Restaurant.create(name: "Honey's")
#   user_stub = OpenStruct.new(admin?: true)
#   test_call = RenameRestaurantCall.test.with_context(user: user_stub)
#   result = test_call.execute(restaurant.id, "Board & Brew")
#   # The result has application objects, _not_ nodes:
#   assert_equal("Board & Brew", result[:restaurant].name)
#
# @example Testing modifications to application state
#   # Given node & call above
#   # We could test how the call affects the system
#   restaurant = Restaurant.create(name: "Honey's")
#   user_stub = OpenStruct.new(admin?: true)
#   test_call = RenameRestaurantCall.test.with_context(user: user_stub)
#   test_call.execute(restaurant.id, "Board & Brew")
#
#   # The restaraunt has changed in the database
#   assert_equal("Board & Brew", restaurant.reload.name)
#
# @example Testing the same node with different contexts
#   # Given node & call above
#   # We could test how the call behaves when given different contexts
#   restaurant = Restaurant.create(name: "Honey's")
#   admin_stub = OpenStruct.new(admin?: true)
#   non_admin_stub = OpenStruct.new(admin?: false)
#
#   # Build a test call with arguments:
#   test_call = RenameRestaurantCall.test.with_arguments(restaurant.id, "Board & Brew")
#
#   # Then copy it with the different contexts:
#   admin_test_call     = test_call.with_context(user: admin_stub)
#   non_admin_test_call = test_call.with_context(user: non_admin_stub)
#
#   # Test both calls:
#   assert_equal("Board & Brew",  admin_test_call.execute[:restaurant].name,      "It is changed by Admin")
#   assert_equal("Honey's",       non_admin_test_call.execute[:restaurant].name,  "It is NOT changed by non-Admin")
#
class GraphQL::TestCall
  # Use {RootCall.test} to get a {TestCall} instance.
  def initialize(call_class, context: nil, arguments: [])
    @call_class = call_class
    @context = context
    @arguments = arguments
  end

  # Execute the call with these arguments.
  # If no arguments are provided, the built-in ones (from {#with_arguments}) will be used.
  # Returns application objects from the call, not nodes.
  def execute(*args)
    if args.none?
      args = @arguments
    end

    query_string = as_query_string(args)
    query = GraphQL::Query.new(query_string, context: @context)
    query_args = query.root.nodes[0].arguments
    call = @call_class.new(query: query, syntax_arguments: query_args)
    call.execute!(*args)
  end

  # Return a copy of this {TestCall} with the given context built-in
  def with_context(context)
    self.class.new(@call_class, context: context, arguments: @arguments)
  end

  # Return a copy of this {TestCall} with the given arguments built-in
  def with_arguments(*args)
    self.class.new(@call_class, context: @context, arguments: args)
  end

  private

  def as_query_string(args)
    arg_names = args.length.times.map { |n| "<arg#{n}>" }

    arg_values = args.each_with_index.map do |arg, idx|
      if arg.is_a?(String) || arg.is_a?(Numeric)
        val = "#{arg}"
      else
        val = JSON.dump(arg)
      end
      "<arg#{idx}>: #{val}"
    end

    "#{@call_class.schema_name}(#{arg_names.join(",")}) {
    }
    #{arg_values.join("\n")}
    "
  end
end