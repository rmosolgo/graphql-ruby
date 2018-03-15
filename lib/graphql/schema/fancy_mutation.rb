# frozen_string_literal: true

module GraphQL
  class Schema
    class FancyMutation < Schema::Mutation

      def perform(**kwargs)
        # If an argument was mapped to a method, call that method
        self.class.injections.each do |arg_name, inject_as|
          if kwargs.key?(arg_name)
            raw_value = kwargs.delete(arg_name)
            prepared_value = public_send(inject_as, raw_value)
            if @context.schema.lazy?(prepared_value)
              # TODO actually support batching
              # TODO how _should_ this be organized?
              prepared_value = GraphQL::Field::DefaultLazyResolve.call(prepared_value, nil, @context)
            end
            kwargs[inject_as] = prepared_value
          end
        end

        # Then pass the maybe-transformed kwargs to the real perform method
        perform_really(**kwargs)
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
      end
    end
  end
end
