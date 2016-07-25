module GraphQL
  class Directive
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :locations, :name, :description, :include_proc, argument: GraphQL::Define::AssignArgument

    lazy_defined_attr_accessor :locations, :arguments, :name, :description, :include_proc

    LOCATIONS = [
      QUERY =               :QUERY,
      MUTATION =            :MUTATION,
      SUBSCRIPTION =        :SUBSCRIPTION,
      FIELD =               :FIELD,
      FRAGMENT_DEFINITION = :FRAGMENT_DEFINITION,
      FRAGMENT_SPREAD =     :FRAGMENT_SPREAD,
      INLINE_FRAGMENT =     :INLINE_FRAGMENT,
    ]

    def initialize
      @arguments = {}
    end

    def include?(arguments)
      include_proc.call(arguments)
    end

    def to_s
      "<GraphQL::Directive #{name}>"
    end

    def on_field?
      locations.include?(FIELD)
    end

    def on_fragment?
      locations.include?(FRAGMENT_SPREAD) && locations.include?(INLINE_FRAGMENT)
    end

    def on_operation?
      locations.include?(QUERY) && locations.include?(MUTATION) && locations.include?(SUBSCRIPTION)
    end
  end
end

require "graphql/directive/include_directive"
require "graphql/directive/skip_directive"
