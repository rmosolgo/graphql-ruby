# frozen_string_literal: true
module GraphQL
  class Dataloader
    class MutationFieldExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:, **_rest)
        Dataloader.current.clear
        begin
          return_value = yield(object, arguments)
          GraphQL::Execution::Lazy.sync(return_value)
        ensure
          Dataloader.current.clear
        end
      end
    end
  end
end
