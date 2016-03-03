module GraphQL
  class Directive
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :locations, :name, :description, :include_proc, argument: GraphQL::Define::AssignArgument

    attr_accessor :locations, :arguments, :name, :description

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
      @include_proc.call(arguments)
    end

    def include_proc=(include_proc)
      @include_proc = include_proc
    end

    def to_s
      "<GraphQL::Directive #{name}>"
    end
  end
end

require "graphql/directive/include_directive"
require "graphql/directive/skip_directive"
