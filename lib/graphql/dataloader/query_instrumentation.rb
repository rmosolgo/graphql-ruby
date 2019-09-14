# frozen_string_literal: true

module GraphQL
  class Dataloader
    class QueryInstrumentation
      def initialize(dataloader_context_key:, dataloader_class:)
        @dataloader_class = dataloader_class
        @dataloader_context_key = dataloader_context_key
      end

      def before_query(query)
        dl = @dataloader_class.new(query)
        query.context[@dataloader_context_key] = dl
      end

      def after_query(query)
      end
    end
  end
end
