# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class NoValidateVisitor < StaticValidation::BaseVisitor
      include(GraphQL::InternalRepresentation::Rewrite)
      include(GraphQL::StaticValidation::DefinitionDependencies)
      include(ContextMethods)
    end
  end
end
