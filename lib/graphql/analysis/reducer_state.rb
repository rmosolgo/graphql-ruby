# frozen_string_literal: true
module GraphQL
  module Analysis
    class ReducerState
      attr_reader :reducer
      attr_accessor :memo, :errors

      def initialize(reducer, query)
        @reducer = reducer
        @memo = initialize_reducer(reducer, query)
        @errors = []
      end

      def call(visit_type, irep_node)
        @memo = @reducer.call(@memo, visit_type, irep_node)
      rescue AnalysisError => err
        @errors << err
      end

      # Respond with any errors, if found. Otherwise, if the reducer accepts
      # `final_value`, send it the last memo value.
      # Otherwise, use the last value from the traversal.
      # @return [Any] final memo value
      def finalize_reducer
        if @errors.any?
          @errors
        elsif reducer.respond_to?(:final_value)
          reducer.final_value(@memo)
        else
          @memo
        end
      end

      private

      # If the reducer has an `initial_value` method, call it and store
      # the result as `memo`. Otherwise, use `nil` as memo.
      # @return [Any] initial memo value
      def initialize_reducer(reducer, query)
        if reducer.respond_to?(:initial_value)
          reducer.initial_value(query)
        else
          nil
        end
      end
    end
  end
end
