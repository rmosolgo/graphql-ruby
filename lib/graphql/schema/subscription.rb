# frozen_string_literal: true

module GraphQL
  class Schema
    # This class can be extended to create fields on your subscription root.
    #
    # It provides hooks for the different parts of the subscription lifecycle:
    #
    # - `#authorized?`: called before initial subscription and subsequent updates
    # - `#subscribe`: called for the initial subscription
    # - `#update`: called for subsequent update
    #
    # Also, `#unsubscribe` terminates the subscription.
    class Subscription < GraphQL::Schema::Resolver
      extend GraphQL::Schema::Resolver::HasPayloadType
      extend GraphQL::Schema::Member::HasFields
      NO_UPDATE = :no_update
      # The generated payload type is required; If there's no payload,
      # propagate null.
      null false

      def initialize(object:, context:, field:)
        super
        # Figure out whether this is an update or an initial subscription
        @mode = context.query.subscription_update? ? :update : :subscribe
      end

      def resolve_with_support(**args)
        result = nil
        unsubscribed = true
        catch :graphql_subscription_unsubscribed do
          result = super
          unsubscribed = false
        end


        if unsubscribed
          context.skip
        else
          result
        end
      end

      # Implement the {Resolve} API
      def resolve(**args)
        # Dispatch based on `@mode`, which will raise a `NoMethodError` if we ever
        # have an unexpected `@mode`
        public_send("resolve_#{@mode}", **args)
      end

      # Wrap the user-defined `#subscribe` hook
      def resolve_subscribe(**args)
        ret_val = args.any? ? subscribe(**args) : subscribe
        if ret_val == :no_response
          context.skip
        else
          ret_val
        end
      end

      # The default implementation returns nothing on subscribe.
      # Override it to return an object or
      # `:no_response` to (explicitly) return nothing.
      def subscribe(args = {})
        :no_response
      end

      # Wrap the user-provided `#update` hook
      def resolve_update(**args)
        ret_val = args.any? ? update(**args) : update
        if ret_val == NO_UPDATE
          context.namespace(:subscriptions)[:no_update] = true
          context.skip
        else
          ret_val
        end
      end

      # The default implementation returns the root object.
      # Override it to return {NO_UPDATE} if you want to
      # skip updates sometimes. Or override it to return a different object.
      def update(args = {})
        object
      end

      # If an argument is flagged with `loads:` and no object is found for it,
      # remove this subscription (assuming that the object was deleted in the meantime,
      # or that it became inaccessible).
      def load_application_object_failed(err)
        if @mode == :update
          unsubscribe
        end
        super
      end

      # Call this to halt execution and remove this subscription from the system
      def unsubscribe
        context.namespace(:subscriptions)[:unsubscribed] = true
        throw :graphql_subscription_unsubscribed
      end

      READING_SCOPE = ::Object.new
      # Call this method to provide a new subscription_scope; OR
      # call it without an argument to get the subscription_scope
      # @param new_scope [Symbol]
      # @param optional [Boolean] If true, then don't require `scope:` to be provided to updates to this subscription.
      # @return [Symbol]
      def self.subscription_scope(new_scope = READING_SCOPE, optional: false)
        if new_scope != READING_SCOPE
          @subscription_scope = new_scope
          @subscription_scope_optional = optional
        elsif defined?(@subscription_scope)
          @subscription_scope
        else
          find_inherited_value(:subscription_scope)
        end
      end

      def self.subscription_scope_optional?
        if defined?(@subscription_scope_optional)
          @subscription_scope_optional
        else
          find_inherited_value(:subscription_scope_optional, false)
        end
      end

      # This is called during initial subscription to get a "name" for this subscription.
      # Later, when `.trigger` is called, this will be called again to build another "name".
      # Any subscribers with matching topic will begin the update flow.
      #
      # The default implementation creates a string using the field name, subscription scope, and argument keys and values.
      # In that implementation, only `.trigger` calls with _exact matches_ result in updates to subscribers.
      #
      # To implement a filtered stream-type subscription flow, override this method to return a string with field name and subscription scope.
      # Then, implement {#update} to compare its arguments to the current `object` and return {NO_UPDATE} when an
      # update should be filtered out.
      #
      # @see {#update} for how to skip updates when an event comes with a matching topic.
      # @param arguments [Hash<String => Object>] The arguments for this topic, in GraphQL-style (camelized strings)
      # @param field [GraphQL::Schema::Field]
      # @param scope [Object, nil] A value corresponding to `.trigger(... scope:)` (for updates) or the `subscription_scope` found in `context` (for initial subscriptions).
      # @return [String] An identifier corresponding to a stream of updates
      def self.topic_for(arguments:, field:, scope:)
        Subscriptions::Serialize.dump_recursive([scope, field.graphql_name, arguments])
      end
    end
  end
end
