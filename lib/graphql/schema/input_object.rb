# frozen_string_literal: true
module GraphQL
  class Schema
    class InputObject < GraphQL::Schema::Member
      extend GraphQL::Delegate
      extend GraphQL::Schema::Member::HasArguments

      def initialize(values, context:, defaults_used:)
        @arguments = self.class.arguments_class.new(values, context: context, defaults_used: defaults_used)
        @context = context
      end

      # @return [GraphQL::Query::Context] The context for this query
      attr_reader :context

      # @return [GraphQL::Query::Arguments] The underlying arguments instance
      attr_reader :arguments

      # A lot of methods work just like GraphQL::Arguments
      def_delegators :@arguments, :[], :key?, :to_h
      def_delegators :to_h, :keys, :values, :each, :any?

      class << self
        # @return [Class<GraphQL::Arguments>]
        attr_accessor :arguments_class

        def argument(*args)
          argument_defn = super
          # Add a method access
          arg_name = argument_defn.graphql_definition.name
          define_method(Member::BuildType.underscore(arg_name)) do
            @arguments.public_send(arg_name)
          end
        end

        def to_graphql
          type_defn = GraphQL::InputObjectType.new
          type_defn.name = graphql_name
          type_defn.description = description
          arguments.each do |name, arg|
            type_defn.arguments[arg.graphql_definition.name] = arg.graphql_definition
          end
          # Make a reference to a classic-style Arguments class
          self.arguments_class = GraphQL::Query::Arguments.construct_arguments_class(type_defn)
          # But use this InputObject class at runtime
          type_defn.arguments_class = self
          type_defn
        end
      end
    end
  end
end
