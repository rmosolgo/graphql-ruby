class GraphQL::Field
  extend GraphQL::Definable
  attr_definable(:arguments, :deprecation_reason, :name, :description, :type)

  def initialize
    @arguments = {}
    @resolve_proc = -> (o, a, c) { GraphQL::Query::DEFAULT_RESOLVE }
    yield(self, GraphQL::TypeDefiner.instance, GraphQL::FieldDefiner.instance, GraphQL::ArgumentDefiner.instance)
  end

  def arguments(new_arguments=nil)
    if !new_arguments.nil?
      self.arguments=(new_arguments)
    end
    @arguments
  end

  def arguments=(new_arguments)
    @arguments = GraphQL::StringNamedHash.new(new_arguments).to_h
  end


  # Used when defining:
  #   resolve -> (obj, args, ctx) { obj.get_value }
  # Also used when executing queries:
  #   field.resolve(obj, args, ctx)
  def resolve(proc_or_object, arguments=nil, ctx=nil)
    if arguments.nil? && ctx.nil?
      @resolve_proc = proc_or_object
    else
      @resolve_proc.call(proc_or_object, arguments, ctx)
    end
  end

  # You can pass a proc which will cause the type to be lazy-evaled,
  # That's nice if you have load-order issues
  def type(type_or_proc=nil)
    if !type_or_proc.nil?
      @type = type_or_proc
    elsif @type.is_a?(Proc)
      # lazy-eval it
      @type = @type.call
    end
    @type
  end
end
