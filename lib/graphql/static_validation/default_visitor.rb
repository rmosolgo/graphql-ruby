# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class DefaultVisitor < BaseVisitor
      StaticValidation::ALL_RULES.reverse_each do |r|
        include(r)
      end

      prepend(ContextMethods)
    end
  end
end
