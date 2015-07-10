class GraphQL::Field < GraphQL::AbstractField
  extend GraphQL::Definable
  REQUIRED_DEFINITIONS = [:name, :description, :type]
  attr_definable(:arguments, :deprecation_reason, *REQUIRED_DEFINITIONS)

  def initialize(&block)
    @arguments = {}
    yield(self) if block_given?
    REQUIRED_DEFINITIONS.each do |defn|
      if public_send(defn).nil?
        raise(ArgumentError, "Field #{name || "<no name>"} must define #{defn}!")
      end
    end
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
end
