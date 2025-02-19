# frozen_string_literal: true

module GraphQLTracingPerfettoSamplerBackendAssertions
  def self.included(child_class)
    child_class.instance_eval do
      describe "BackendAssertions" do
        before do
          @backend.delete_all_traces
        end

        it "can save, retreive, list, and delete traces" do
          data = SecureRandom.bytes(1000)
          trace_id = @backend.save_trace(
            "GetStuff",
            100.56,
            Time.utc(2024, 01, 01, 04, 44, 33, 695),
            data
          )

          trace = @backend.find_trace(trace_id)
          assert_kind_of GraphQL::Tracing::PerfettoSampler::StoredTrace, trace
          assert_equal "GetStuff", trace.operation_name
          assert_equal 100.56, trace.duration_ms
          assert_equal "2024-01-01 04:44:33.000", trace.timestamp.utc.strftime("%Y-%m-%d %H:%M:%S.%L")
          assert_equal data, trace.trace_data


          @backend.save_trace(
            "GetOtherStuff",
            200.16,
            Time.utc(2024, 01, 03, 04, 44, 33, 695),
            data
          )

          assert_equal ["GetStuff", "GetOtherStuff"], @backend.traces.map(&:operation_name)

          @backend.delete_trace(trace_id)

          assert_equal ["GetOtherStuff"], @backend.traces.map(&:operation_name)

          @backend.delete_all_traces
          assert_equal [], @backend.traces
        end

        it "returns nil for nonexistent IDs" do
          assert_nil @backend.find_trace(999_999_999)
        end
      end
    end
  end
end
