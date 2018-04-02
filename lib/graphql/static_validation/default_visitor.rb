# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class DefaultVisitor < BaseVisitor
      include(GraphQL::StaticValidation::DefinitionDependencies)

      StaticValidation::ALL_RULES.reverse_each do |r|
        include(r)
      end

      include(GraphQL::InternalRepresentation::Rewrite)
      include(ContextMethods)
    end
  end
end
