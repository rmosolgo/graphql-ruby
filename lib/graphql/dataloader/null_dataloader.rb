# frozen_string_literal: true

module GraphQL
  class Dataloader
    # The default implementation of dataloading -- all no-ops.
    #
    # The Dataloader interface isn't public, but it enables
    # simple internal code while adding the option to add Dataloader.
    class NullDataloader < Dataloader
      # These are all no-ops because code was
      # executed sychronously.
      def run; end
      def yield; end

      def append_job
        yield
        nil
      end
    end
  end
end
