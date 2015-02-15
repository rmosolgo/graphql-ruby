class GraphQL::RootCall
  attr_reader :query, :arguments
  def initialize(query:, syntax_arguments:)
    @query = query
    @arguments = syntax_arguments.map do |syntax_arg|
      if syntax_arg[0] == "<"
        query.get_variable(syntax_arg)
      else
        syntax_arg
      end
    end
  end

  def execute!(*args)
    raise NotImplementedError, "Do work in this method"
  end

  def as_result
    execute!(*arguments)
  end

  class << self
    def indentifier(ident_name)
      @identifier = ident_name
    end

    def schema_name
      @identifier || name.split("::").last.sub(/Call$/, '').underscore
    end

    def inherited(child_class)
      GraphQL::SCHEMA.add_call(child_class)
    end
  end
end