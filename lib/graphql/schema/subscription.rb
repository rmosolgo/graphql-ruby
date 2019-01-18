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

      def initialize(object:, context:)
        super
        # Figure out whether this is an update or an initial subscription
        @mode = context.query.subscription_update? ? :update : :subscribe
      end

      # Implement the {Resolve} API
      def resolve(**args)
        # Dispatch based on `@mode`, which will raise a `NoMethodError` if we ever
        # have an unexpected `@mode`
        public_send("resolve_#{@mode}", args)
      end

      # Wrap the user-defined `#subscribe` hook
      def resolve_subscribe(args)
        ret_val = subscribe(args)
        if ret_val == :no_response
          context.skip
        else
          ret_val
        end
      end

      # Default implementation returns the root object.
      # Override it to return a different object or
      # `:no_response` to change the initial response.
      # TODO default should be :no_response for compat?
      def subscribe(args)
        object
      end

      # Wrap the user-provided `#update` hook
      def resolve_update(args)
        ret_val = update(args)
        if ret_val == :no_update
          # TODO: this needs to be something _else_, that tells
          # the transport system to _make no send at all_.
          #
          # Or, maybe the transport side should _check_ whether any
          # root fields are present, and if not, skip the send.
          context.skip
        else
          ret_val
        end
      end

      # The default implementation returns the root object.
      # Override it to return `:no_update` if you want to
      # skip updates sometimes. Or override it to return a different object.
      def update(args)
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
    end
  end
end
