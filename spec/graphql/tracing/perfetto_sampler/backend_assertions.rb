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
            (Time.utc(2024, 01, 01, 04, 44, 33, 695000).to_f * 1000).round,
            data
          )

          trace = @backend.find_trace(trace_id)
          assert_kind_of GraphQL::Tracing::PerfettoSampler::StoredTrace, trace
          assert_equal trace_id, trace.id
          assert_equal "GetStuff", trace.operation_name
          assert_equal 100.56, trace.duration_ms
          assert_equal "2024-01-01 04:44:33.694", Time.at(trace.timestamp / 1000.0).utc.strftime("%Y-%m-%d %H:%M:%S.%L")
          assert_equal data, trace.trace_data


          @backend.save_trace(
            "GetOtherStuff",
            200.16,
            (Time.utc(2024, 01, 03, 04, 44, 33, 695000).to_f * 1000).round,
            data
          )

          @backend.save_trace(
            "GetMoreOtherStuff",
            200.16,
            (Time.utc(2024, 01, 03, 04, 44, 33, 795000).to_f * 1000).round,
            data
          )

          assert_equal ["GetMoreOtherStuff", "GetOtherStuff", "GetStuff" ], @backend.traces(last: 20, before: nil).map(&:operation_name)

          assert_equal ["GetMoreOtherStuff"], @backend.traces(last: 1, before: nil).map(&:operation_name)
          assert_equal ["GetOtherStuff", "GetStuff"], @backend.traces(last: 2, before: Time.utc(2024, 01, 03, 04, 44, 33, 795000).to_f * 1000).map(&:operation_name)


          @backend.delete_trace(trace_id)

          assert_equal ["GetMoreOtherStuff", "GetOtherStuff"], @backend.traces(last: 20, before: nil).map(&:operation_name)

          @backend.delete_all_traces
          assert_equal [], @backend.traces(last: 20, before: nil)
        end

        it "returns nil for nonexistent IDs" do
          assert_nil @backend.find_trace(999_999_999)
        end
      end
    end
  end
end
