# This implementation of `Directive` is ... not robust.
# It seems like this area of the spec is still getting worked out, so
# {Directive} & {DirectiveChain} implement `@skip` and `@include` with
# minimal impact on query execution.
class GraphQL::Directive
  include GraphQL::DefinitionHelpers::DefinedByConfig
  attr_accessor :on, :arguments, :name, :description, :resolve_proc

  LOCATIONS = [
    ON_OPERATION =  :on_operation?,
    ON_FRAGMENT =   :on_fragment?,
    ON_FIELD =      :on_field?,
  ]

  LOCATIONS.each do |location|
    define_method(location) { self.on.include?(location) }
  end

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :on, :arguments, :name, :description, :resolve

    def initialize
      @arguments = {}
      @on = []
    end

    def argument(name, type, description = nil, default_value: nil)
      @arguments[name.to_s] = GraphQL::Argument.new(
        name: name.to_s,
        type: type,
        description: description,
        default_value: nil,
      )
    end

    def to_instance
      instance = GraphQL::Directive.new
      instance.on = on
      instance.arguments = arguments
      instance.name = name
      instance.description = description
      instance.resolve_proc = resolve
      instance
    end
  end

  def resolve(arguments, proc)
    @resolve_proc.call(arguments, proc)
  end

  def to_s
    "<GraphQL::Directive #{name}>"
  end
end

require 'graphql/directive/include_directive'
require 'graphql/directive/skip_directive'
