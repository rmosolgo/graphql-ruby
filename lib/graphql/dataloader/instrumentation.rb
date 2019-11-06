# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Instrumentation
      def initialize(dataloader_class:)
        @dataloader_class = dataloader_class
      end

      def before_multiplex(multiplex)
        dl = @dataloader_class.new(multiplex)
        multiplex.context[:dataloader] = dl
        multiplex.queries.each do |q|
          q.context[:dataloader] = dl
        end
      end

      def after_multiplex(_m)
      end
    end
  end
end
