# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class NoValidateVisitor < StaticValidation::BaseVisitor
      prepend(StaticValidation::BaseVisitor::ContextMethods)
    end
  end
end
