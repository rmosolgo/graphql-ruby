# frozen_string_literal: true
module GraphQL
  class Subscriptions
    class TriggerJob < ActiveJob::Base
      class << self
        # @return [GraphQL::Subscriptions]
        attr_accessor :subscriptions
      end

      def perform(*args, **kwargs)
        self.class.subscriptions.trigger(*args, **kwargs)
      end
    end
  end
end
