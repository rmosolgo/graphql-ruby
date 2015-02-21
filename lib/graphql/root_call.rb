class GraphQL::RootCall
  attr_reader :query, :arguments
  def initialize(query:, syntax_arguments:)
    @query = query

    raise "#{self.class.name} must declare arguments" unless self.class.arguments
    @arguments = syntax_arguments.each_with_index.map do |syntax_arg, idx|

      value = if syntax_arg[0] == "<"
          query.get_variable(syntax_arg).json_string
        else
          syntax_arg
        end

      self.class.typecast(idx, value)
    end
  end

  def execute!(*args)
    raise NotImplementedError, "Do work in this method"
  end

  def context
    query.context
  end

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
    def indentifier(ident_name)
      @identifier = ident_name
    end

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

    def argument
      @argument ||= GraphQL::RootCallArgumentDefiner.new(self)
    end

    def own_arguments
      @argument && @argument.arguments
    end

    def arguments
      own = own_arguments || []
      own + superclass.arguments
    rescue NoMethodError
      own
    end

    def argument_for_index(idx)
      if arguments.first.any_number
        arguments.first
      else
        arguments[idx]
      end
    end

    TYPE_CHECKS = {
      "object" => Hash,
      "number" => Numeric,
      "string" => String,
    }

    def typecast(idx, value)
      arg_dec = argument_for_index(idx)
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

    def schema_name
      @identifier || name.split("::").last.sub(/Call$/, '').underscore
    end

    def inherited(child_class)
      GraphQL::SCHEMA.add_call(child_class)
    end
  end
end