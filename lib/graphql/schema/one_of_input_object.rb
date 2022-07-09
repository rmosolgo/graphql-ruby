# frozen_string_literal: true

module GraphQL
  class Schema
    class OneOfInputObject < GraphQL::Schema::InputObject
      class << self
        def inherited(cls)
          cls.directive GraphQL::Schema::Directive::OneOf
        end

        def member(*args, **kwargs, &block)
          argument(*args, **kwargs, &block)
        end
      end
    end
  end
end
