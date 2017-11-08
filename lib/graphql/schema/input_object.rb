# frozen_string_literal: true
module GraphQL
  class Schema
    class InputObject < GraphQL::Schema::Member
      extend GraphQL::Delegate

      def initialize(values, context:, defaults_used:)
        @arguments = self.class.arguments_class.new(values, context: context, defaults_used: defaults_used)
        @context = context
      end

      # A lot of methods work just like GraphQL::Arguments
      def_delegators :@arguments, :[], :key?, :to_h
      def_delegators :to_h, :keys, :values, :each, :any?

      class << self
        # @return [Class<GraphQL::Arguments>]
        attr_accessor :arguments_class

        def argument(*args)
          argument = GraphQL::Schema::Argument.new(*args)
          own_arguments << argument
          arg_name = argument.name
          # Add a method access
          define_method(Member::BuildType.underscore(arg_name)) do
            @arguments.public_send(arg_name)
          end
        end

        def arguments
          all_arguments = own_arguments
          inherited_arguments = (superclass <= GraphQL::Schema::InputObject ? superclass.arguments : [])
          inherited_arguments.each do |inherited_a|
            if all_arguments.none? { |a| a.name == inherited_a.name }
              all_arguments << inherited_a
            end
          end
          all_arguments
        end

        def own_arguments
          @own_arguments ||= []
        end

        def to_graphql
          type_defn = GraphQL::InputObjectType.new
          type_defn.name = graphql_name
          type_defn.description = description
          arguments.each do |arg|
            type_defn.arguments[arg.name] = arg.graphql_definition
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
