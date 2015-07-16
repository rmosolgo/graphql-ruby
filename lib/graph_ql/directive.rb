class GraphQL::Directive < GraphQL::ObjectType
  LOCATIONS = [
    ON_OPERATION =  :on_operation?,
    ON_FRAGMENT =   :on_fragment?,
    ON_FIELD =      :on_field?,
  ]
  LOCATIONS.each do |location|
    define_method(location) { self.on.include?(location) }
  end

  attr_definable :on, :arguments

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
      @arguments = new_arguments
        .reduce({}) {|memo, (k, v)| memo[k.to_s] = v; memo}
        .each { |k, v| v.respond_to?("name=") && v.name = k}
    end
    @arguments
  end
end

require 'graph_ql/directives/directive_chain'
require 'graph_ql/directives/include_directive'
require 'graph_ql/directives/skip_directive'
