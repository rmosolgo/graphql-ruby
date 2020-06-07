# frozen_string_literal: true

module GraphQL
  class Subscriptions
    # Detect whether the current operation:
    # - Is a subscription operation
    # - Is completely broadcastable
    #
    # Assign the result to `context.namespace(:subscriptions)[:subscription_broadcastable]`
    class BroadcastAnalyzer < GraphQL::Analysis::AST::Analyzer
      def initialize(subject)
        super
        @default_broadcastable = subject.schema.subscriptions.default_broadcastable
        # Maybe this will get set to false while analyzing
        @subscription_broadcastable = true
      end

      # Only analyze subscription operations
      def analyze?
        @query.subscription?
      end

      def on_enter_field(node, parent, visitor)
        if (@subscription_broadcastable == false) || visitor.skipping?
          return
        end

        current_field = visitor.field_definition
        current_field_broadcastable = current_field.broadcastable?
        case current_field_broadcastable
        when nil
          # If the value wasn't set, mix in the default value:
          # - If the default is false and the current value is true, make it false
          # - If the default is true and the current value is true, it stays true
          # - If the default is false and the current value is false, keep it false
          # - If the default is true and the current value is false, keep it false
          @subscription_broadcastable = @subscription_broadcastable && @default_broadcastable
        when false
          # One non-broadcastable field is enough to make the whole subscription non-broadcastable
          @subscription_broadcastable = false
        when true
          # Leave `@broadcastable_query` true if it's already true,
          # but don't _set_ it to true if it was set to false by something else.
          # Actually, just leave it!
        else
          raise ArgumentError, "Unexpected `.broadcastable?` value for #{current_field.path}: #{current_field_broadcastable}"
        end
      end

      def result
        query.context.namespace(:subscriptions)[:subscription_broadcastable] = @subscription_broadcastable
      end
    end
  end
end
