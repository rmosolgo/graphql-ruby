class GraphQL::Directive
  extend GraphQL::Definable
  attr_definable :on, :arguments, :name, :description

  LOCATIONS = [
    ON_OPERATION =  :on_operation?,
    ON_FRAGMENT =   :on_fragment?,
    ON_FIELD =      :on_field?,
  ]
  LOCATIONS.each do |location|
    define_method(location) { self.on.include?(location) }
  end


  def initialize
    @arguments = {}
    @on = []
    yield(self, GraphQL::TypeDefiner.instance, GraphQL::FieldDefiner.instance, GraphQL::ArgumentDefiner.instance)
  end

  def resolve(proc_or_arguments, proc=nil)
    if proc.nil?
      # resolve is being defined, just set it
      @resolve_proc = proc_or_arguments
    else
      @resolve_proc.call(proc_or_arguments, proc)
    end
  end

  def arguments(new_arguments=nil)
    if !new_arguments.nil?
      @arguments = GraphQL::StringNamedHash.new(new_arguments).to_h
    end
    @arguments
  end

  def to_s
    "<GraphQL::Directive #{name}>"
  end
end

require 'graph_ql/directives/directive_chain'
require 'graph_ql/directives/include_directive'
require 'graph_ql/directives/skip_directive'
