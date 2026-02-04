# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

if testing_rails?
  describe GraphQL::Tracing::DetailedTrace::ActiveRecordBackend do
    include GraphQLTracingDetailedTraceBackendAssertions
    def new_backend(**kwargs)
      GraphQL::Tracing::DetailedTrace::ActiveRecordBackend.new(**kwargs)
    end
  end
end
