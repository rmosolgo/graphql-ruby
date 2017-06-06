# frozen_string_literal: true
module GraphQL
  # Helpers for migrating in a backwards-compatibile way
  # @api private
  module BackwardsCompatibility
    module_function
    # Given a callable whose API used to take `from` arguments,
    # check its arity, and if needed, apply a wrapper so that
    # it can be called with `to` arguments.
    # If a wrapper is applied, warn the application with `name`.
    def wrap_arity(callable, from:, to:, name:)
      arity = get_arity(callable)
      case arity
      when to
        # It already matches, return it as is
        callable
      when from
        # It has the old arity, so wrap it with an arity converter
        warn("#{name} with #{from} arguments is deprecated, it now accepts #{to} arguments")
        ArityWrapper.new(callable, from)
      else
        raise "Can't wrap #{callable} (arity: #{arity}) to have arity #{to}"
      end
    end

    def get_arity(callable)
      case callable
      when Method, Proc
        callable.arity
      else
        callable.method(:call).arity
      end
    end

    class ArityWrapper
      def initialize(callable, old_arity)
        @callable = callable
        @old_arity = old_arity
      end

      def call(*args)
        backwards_compat_args = args.first(@old_arity)
        @callable.call(*backwards_compat_args)
      end
    end
  end
end
