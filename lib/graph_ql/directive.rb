class GraphQL::Directive
  ON_OPERATION =  :on_operation
  ON_FRAGMENT =   :on_fragment
  ON_FIELD =      :on_field

  extend GraphQL::Definable
  attr_definable :name, :on, :description, :arguments

  def initialize(&block)
    @arguments = {}
    @on = []
    yield(self) if block_given?
  end

  def resolve(proc_or_arguments, proc=nil)
    if proc.nil?
      @resolve_proc = proc_or_arguments
    else
      @resolve_proc.call(proc_or_arguments, proc)
    end
  end
end

# type __Directive {
#   name: String!
#   description: String
#   args: [__InputValue!]!
#   onOperation: Boolean!
#   onFragment: Boolean!
#   onField: Boolean!
# }
