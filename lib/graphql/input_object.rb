# frozen_string_literal: true
module GraphQL
  class InputObject < GraphQL::SchemaMember
    class << self
      def argument(*args)
        arguments << GraphQL::Object::Argument.new(*args)
      end

      # TODO inheritance
      def arguments
        @arguments ||= []
      end

      def to_graphql
        type_defn = GraphQL::InputObjectType.new
        type_defn.name = graphql_name
        type_defn.description = description
        arguments.each do |arg|
          type_defn.arguments[arg.name] = arg.to_graphql
        end
        type_defn
      end
    end
  end
end
