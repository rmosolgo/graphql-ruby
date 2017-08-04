# frozen_string_literal: true
module GraphQL
  module Subscriptions
    # This "in-memory" database
    # will only work for a single server,
    # like your development environment.
    #
    # In case of a crash, restart or redeploy,
    # it loses all state.
    # @api private
    class MemoryStore

    end
  end
end
