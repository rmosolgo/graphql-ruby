# This implementation of `Directive` is ... not robust.
# It seems like this area of the spec is still getting worked out, so
# {Directive} & {DirectiveChain} implement `@skip` and `@include` with
# minimal impact on query execution.
class GraphQL::Directive
  extend GraphQL::DefinitionHelpers::Definable
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
    yield(
      self,
      GraphQL::DefinitionHelpers::TypeDefiner.instance,
      GraphQL::DefinitionHelpers::FieldDefiner.instance,
      GraphQL::DefinitionHelpers::ArgumentDefiner.instance
    )
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
      @arguments = GraphQL::DefinitionHelpers::StringNamedHash.new(new_arguments).to_h
    end
    @arguments
  end

  def to_s
    "<GraphQL::Directive #{name}>"
  end
end

require 'graphql/directive/include_directive'
require 'graphql/directive/skip_directive'
