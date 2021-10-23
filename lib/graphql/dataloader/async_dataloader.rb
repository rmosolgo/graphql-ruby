# frozen_string_literal: true
require 'fiber'

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def initialize
        super(nonblocking: true)
      end
    end
  end
end
