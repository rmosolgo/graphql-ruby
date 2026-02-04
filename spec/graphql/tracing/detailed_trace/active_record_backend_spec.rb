# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

if testing_rails?
  describe GraphQL::Tracing::DetailedTrace::ActiveRecordBackend do
    include GraphQLTracingDetailedTraceBackendAssertions
    def new_backend(**kwargs)
      GraphQL::Tracing::DetailedTrace::ActiveRecordBackend.new(**kwargs)
    end

    class DummyModel
      def self.find_by(id:)
        OpenStruct.new(
          trace_data: Base64.encode64("DummyModel##{id}")
        )
      end
    end

    it "can use a custom model class" do
      schema = Class.new(GraphQL::Schema) do
        use GraphQL::Tracing::DetailedTrace, model_class: DummyModel
      end

      assert_equal "DummyModel#1234", schema.detailed_trace.find_trace(1234).trace_data
    end
  end
end
