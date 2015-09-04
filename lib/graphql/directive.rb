# This implementation of `Directive` is ... not robust.
# It seems like this area of the spec is still getting worked out, so
# {Directive} & {DirectiveChain} implement `@skip` and `@include` with
# minimal impact on query execution.
class GraphQL::Directive
  include GraphQL::DefinitionHelpers::DefinedByConfig
  attr_accessor :on, :arguments, :name, :description
  defined_by_config :on, :arguments, :name, :description, :resolve

  LOCATIONS = [
    ON_OPERATION =  :on_operation?,
    ON_FRAGMENT =   :on_fragment?,
    ON_FIELD =      :on_field?,
  ]

  LOCATIONS.each do |location|
    define_method(location) { self.on.include?(location) }
  end

  def resolve(arguments, proc)
    @resolve_proc.call(arguments, proc)
  end

  def resolve=(resolve_proc)
    @resolve_proc = resolve_proc
  end

  def to_s
    "<GraphQL::Directive #{name}>"
  end
end

require 'graphql/directive/include_directive'
require 'graphql/directive/skip_directive'
