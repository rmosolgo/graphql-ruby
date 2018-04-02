# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class NoValidateVisitor < StaticValidation::BaseVisitor
      include(GraphQL::InternalRepresentation::Rewrite)
      include(GraphQL::StaticValidation::DefinitionDependencies)
      prepend(ContextMethods)
    end
  end
end
