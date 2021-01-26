# frozen_string_literal: true
module GraphQL
  # Helpers for migrating in a backwards-compatible way
  # Remove this in GraphQL-Ruby 2.0, when all users of it will be gone.
  # @api private
  module BackwardsCompatibility
    module_function
    # Given a callable whose API used to take `from` arguments,
    # check its arity, and if needed, apply a wrapper so that
    # it can be called with `to` arguments.
    # If a wrapper is applied, warn the application with `name`.
    #
    # If `last`, then use the last arguments to call the function.
    def wrap_arity(callable, from:, to:, name:, last: false)
      arity = get_arity(callable)
      if arity == to || arity < 0
        # It already matches, return it as is
        callable
      elsif arity == from
        # It has the old arity, so wrap it with an arity converter
        message ="#{name} with #{from} arguments is deprecated, it now accepts #{to} arguments, see:"
        backtrace = caller(0, 20)
        # Find the first line in the trace that isn't library internals:
        user_line = backtrace.find {|l| l !~ /lib\/graphql/ }
        GraphQL::Deprecation.warn(message + "\n" + user_line + "\n")
        wrapper = last ? LastArgumentsWrapper : FirstArgumentsWrapper
        wrapper.new(callable, from)
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

    class FirstArgumentsWrapper
      def initialize(callable, old_arity)
        @callable = callable
        @old_arity = old_arity
      end

      def call(*args)
        backwards_compat_args = args.first(@old_arity)
        @callable.call(*backwards_compat_args)
      end
    end

    class LastArgumentsWrapper < FirstArgumentsWrapper
      def call(*args)
        backwards_compat_args = args.last(@old_arity)
        @callable.call(*backwards_compat_args)
      end
    end
  end
end
