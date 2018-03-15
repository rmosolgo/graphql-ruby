# frozen_string_literal: true

module GraphQL
  class Schema
    # A Mutation class that adds bells and whistles.
    #
    # Implement `#mutate(**kwargs)` to use this class.
    #
    # - Accepts `argument(... inject:)` to transform/rename an argument, using the specified method
    # - Calls `before_mutate` where you can raise a `UserError`
    # - Always has a `userErrors` field
    # - Handles `raise GraphQL::UserError` by putting it in `userErrors`
    #
    # TODO: rename
    class FancyMutation < Schema::Mutation
      # Perform with a few steps:
      # - Pass inputs through transformation methods, if there are any
      # - Call the before_ hook
      # - Call mutate
      def perform(**kwargs)
        # If an argument was mapped to a method, call that method
        self.class.injections.each do |arg_name, inject_as|
          if kwargs.key?(arg_name)
            # Get the raw user input
            raw_value = kwargs.delete(arg_name)
            begin
              # Pass it to the named method
              prepared_value = public_send(inject_as, raw_value)
            rescue GraphQL::UserError => err
              err.fields = @path + [arg_name.to_s]
              raise
            end

            if @context.schema.lazy?(prepared_value)
              # TODO actually support batching
              # TODO how _should_ this be organized?
              prepared_value = GraphQL::Field::DefaultLazyResolve.call(prepared_value, nil, @context)
            end

            # Re-assign it to the named key
            kwargs[inject_as] = prepared_value
          end
        end

        # May raise an error to halt before performing the side-effect
        before_mutate(**kwargs)
        # Then pass the maybe-transformed kwargs to the real perform method
        success_result = mutate(**kwargs)
        # Make sure this is present, since it's non-null:
        success_result[:user_errors] ||= []
        success_result
      rescue GraphQL::UserError => err
        # Maybe already set by argument
        err.fields ||= @path
        { user_errors: [err] }
      end

      # @raise [GraphQL::UserError] Raises to halt execution of the mutation
      # @return [void]
      def before_mutate(**kwargs)
        # pass, users may override this method to raise
      end

      # TODO custom error type class?
      class UserErrorType < GraphQL::Schema::Object
        field :message, String, null: false
        field :fields, [String], null: false
      end

      class << self
        def argument(*args, inject: nil, **kwargs)
          if inject
            name = args[0]
            injections[name] = inject
          end
          super(*args, **kwargs)
        end

        def injections
          @injections ||= {}
        end

        # Extend the payload type to have a `userErrors` field.
        def generate_payload_type
          obj_type_class = super
          obj_type_class.field(:user_errors, [UserErrorType], null: false)
          obj_type_class
        end
      end
    end
  end
end
