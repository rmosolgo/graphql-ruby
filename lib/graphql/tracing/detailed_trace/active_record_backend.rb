# frozen_string_literal: true

module GraphQL
  module Tracing
    class DetailedTrace
      class ActiveRecordBackend
        class GraphqlDetailedTrace < ActiveRecord::Base
        end

        def initialize(limit: nil, model_class: nil)
          @limit = limit
          @model_class = model_class || GraphqlDetailedTrace
        end

        def traces(last:, before:)
          gdts = @model_class.all.order("begin_ms DESC")
          if before
            gdts = gdts.where("begin_ms < ?", before)
          end
          if last
            gdts = gdts.limit(last)
          end
          gdts.map { |gdt| record_to_stored_trace(gdt) }
        end

        def delete_trace(id)
          @model_class.where(id: id).destroy_all
          nil
        end

        def delete_all_traces
          @model_class.all.destroy_all
        end

        def find_trace(id)
          gdt = @model_class.find_by(id: id)
          if gdt
            record_to_stored_trace(gdt)
          else
            nil
          end
        end

        def save_trace(operation_name, duration_ms, begin_ms, trace_data)
          gdt = @model_class.create!(
            begin_ms: begin_ms,
            operation_name: operation_name,
            duration_ms: duration_ms,
            trace_data: Base64.encode64(trace_data),
          )
          if @limit
            @model_class
              .where("id NOT IN(SELECT id FROM graphql_detailed_traces ORDER BY begin_ms DESC LIMIT ?)", @limit)
              .delete_all
          end
          gdt.id
        end

        private

        def record_to_stored_trace(gdt)
          StoredTrace.new(
            id: gdt.id,
            begin_ms: gdt.begin_ms,
            operation_name: gdt.operation_name,
            duration_ms: gdt.duration_ms,
            trace_data: Base64.decode64(gdt.trace_data)
          )

        end
      end
    end
  end
end
