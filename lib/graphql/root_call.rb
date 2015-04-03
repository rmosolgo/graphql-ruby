# Every query begins with a root call. It might find data or mutate data and return some results.
#
# A root call should:
#
# - declare any arguments with {.argument}, or declare `argument.none`
# - declare returns with {.return}
# - implement {#execute!} to take those arguments and return values
#
# @example
#   FindPostCall < GraphQL::RootCall
#     argument.number(:ids, any_number: true)
#     returns :post
#
#     def execute!(*ids)
#       ids.map { |id| Post.find(id) }
#     end
#   end
#
# @example
#   CreateCommentCall < GraphQL::RootCall
#     argument.number(:post_id)
#     argument.object(:comment)
#     returns :post, :comment
#
#     def execute!(post_id, comment)
#       post = Post.find(post_id)
#       new_comment = post.comments.create!(comment)
#       {
#         comment: new_comment,
#         post: post,
#       }
#     end
#   end
#
class GraphQL::RootCall
  attr_reader :query, :arguments

  # Validates arguments against declared {.argument}s
  def initialize(query:, syntax_arguments:)
    @query = query

    raise "#{self.class.name} must declare arguments" unless self.class.arguments
    @arguments = syntax_arguments.each_with_index.map do |syntax_arg, idx|

      value = if syntax_arg[0] == "<"
          query.variables[syntax_arg].json_string
        else
          syntax_arg
        end

      typecast(idx, value)
    end
  end

  # @param [Array] args (splat) all args provided in query string (as strings)
  # This method is invoked with the arguments provided to the query.
  # It should do work and return values matching the {.returns} declarations
  def execute!(*args)
    raise NotImplementedError, "Do work in this method"
  end

  # The object passed to {Query#initialize} as `context`
  def context
    query.context
  end

  # Executes the call, validates the return values against declared {.returns}, then returns the return values.
  def as_result
    return_declarations = self.class.return_declarations
    raise "#{self.class.name} must declare returns" unless return_declarations.present?
    return_values = execute!(*arguments)

    if return_values.is_a?(Hash)
      unexpected_returns = return_values.keys - return_declarations.keys
      missing_returns = return_declarations.keys - return_values.keys
      if unexpected_returns.any?
        raise "#{self.class.name} returned #{unexpected_returns}, but didn't declare them."
      elsif missing_returns.any?
        raise "#{self.class.name} declared #{missing_returns}, but didn't return them."
      end
    end
    return_values
  end

  class << self
    # @param [String] ident_name
    # Declare an alternative name used in a query string
    def indentifier(ident_name)
      @identifier = ident_name
      GraphQL::SCHEMA.add_call(self)
    end

    # The name used by {GraphQL::SCHEMA}. Uses {.identifier} or derives a name from the class name.
    def schema_name
      @identifier || name.split("::").last.sub(/Call$/, '').underscore
    end

    def inherited(child_class)
      GraphQL::SCHEMA.add_call(child_class)
    end

    # This call won't be visible in `schema()`
    def abstract!
      GraphQL::SCHEMA.remove_call(self)
    end

    # @param [Symbol] return_declarations
    # Name of returned values from this call
    def returns(*return_declaration_names)
      if return_declaration_names.last.is_a?(Hash)
        return_declarations_hash = return_declaration_names.pop
      else
        return_declarations_hash = {}
      end

      raise "Return keys must be symbols" if  (return_declarations.keys + return_declaration_names).any? { |k| !k.is_a?(Symbol) }

      return_declaration_names.each do |return_sym|
        return_type = return_sym.to_s
        return_declarations[return_sym] = return_type
      end

      return_declarations_hash.each do |return_sym, return_type|
        return_declarations[return_sym] = return_type
      end
    end

    def return_declarations
      @return_declarations ||= {}
    end

    # @return [GraphQL::RootCallArgumentDefiner] definer
    # Use this object to declare arguments. They must be declared in order
    # @example
    #   argument.string("post_title")
    #   argument.object("comment_data") # allows a JSON object
    def argument
      @argument ||= GraphQL::RootCallArgumentDefiner.new(self)
    end

    def own_arguments
      @own_arguments ||= {}
    end

    def arguments
      superclass.arguments.merge(own_arguments)
    rescue NoMethodError
      {}
    end

    def add_argument(argument)
      existing_argument = arguments[argument.name]
      if existing_argument.blank?
        # only assign an index if this variable wasn't already defined
        argument.index = arguments.keys.length
      else
        # use the same index as the already-defined one
        argument.index = existing_argument.index
      end

      own_arguments[argument.name] = argument
    end

    def argument_at_index(idx)
      if arguments.values.first.any_number
        arguments.values.first
      else
        arguments.values.find { |arg| arg.index == idx } || raise("No argument found for #{name} at index #{JSON.dump(idx)} (argument indexes: #{arguments.values.map(&:index)})")
      end
    end

    # Returns a {TestCall} for this call.
    def test
      GraphQL::TestCall.new(self)
    end
  end

  private

  TYPE_CHECKS = {
    "object" => Hash,
    "number" => Numeric,
    "string" => String,
  }


  def typecast(idx, value)
    arg_dec = self.class.argument_at_index(idx)
    expected_type = arg_dec.type
    expected_type_class = TYPE_CHECKS[expected_type]

    if expected_type == "string"
      parsed_value = value
    else
      parsed_value = JSON.parse('{ "value" : ' + value + '}')["value"]
    end

    if !parsed_value.is_a?(expected_type_class)
      raise GraphQL::RootCallArgumentError.new(arg_dec, value)
    end

    parsed_value
  rescue JSON::ParserError
    raise GraphQL::RootCallArgumentError.new(arg_dec, value)
  end

end