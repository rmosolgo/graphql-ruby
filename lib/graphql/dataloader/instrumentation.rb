# frozen_string_literal: true
module GraphQL
  class Dataloader
    class Instrumentation
      def before_multiplex(multiplex)
        dataloader = Dataloader.new(multiplex)
        Dataloader.begin_dataloading(dataloader)
      end

      def after_multiplex(_m)
        Dataloader.end_dataloading
      end
    end
  end
end
