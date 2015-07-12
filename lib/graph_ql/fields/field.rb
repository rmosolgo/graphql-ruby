class GraphQL::Field < GraphQL::AbstractField
  extend GraphQL::Definable
  REQUIRED_DEFINITIONS = [:name, :description, :type]
  attr_definable(:arguments, :deprecation_reason, *REQUIRED_DEFINITIONS)

  def initialize(&_block)
    @arguments = {}
    @resolve_proc = -> (_o, _a, _c) { GraphQL::Query::DEFAULT_RESOLVE }
    yield(self) if block_given?
  end

  # Used when defining:
  #   resolve -> (obj, args, ctx) { obj.get_value }
  # Also used when executing queries:
  #   field.resolve(obj, args, ctx)
  def resolve(proc_or_object, arguments = nil, ctx = nil)
    if arguments.nil? && ctx.nil?
      @resolve_proc = proc_or_object
    else
      @resolve_proc.call(proc_or_object, arguments, ctx)
    end
  end

  def type(type_or_proc = nil)
    if type_or_proc.nil?
      @type = @type.call if @type.is_a?(Proc)
      @type
    else
      @type = type_or_proc
    end
  end
end
