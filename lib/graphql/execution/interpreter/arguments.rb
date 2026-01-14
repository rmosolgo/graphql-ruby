# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A wrapper for argument hashes in GraphQL queries.
      #
      # This object is immutable so that the runtime code can be sure that
      # modifications don't leak from one use to another
      #
      # @see GraphQL::Query#arguments_for to get access to these objects.
      class Arguments
        extend Forwardable
        include GraphQL::Dig

        # @return [GraphQL::Query::Context]
        attr_reader :context

        # @return [Object, nil]
        attr_reader :parent_object

        # @param argument_values [nil, Hash{Symbol => ArgumentValue}]
        # @param keyword_arguments [nil, Hash{Symbol => Object}]
        def initialize(keyword_arguments: nil, parent_object: nil, context: nil, argument_values:)
          @empty = argument_values.nil? || argument_values.empty?
          @context = context
          @parent_object = parent_object
          # This is only present when `extras` have been merged in:
          @keyword_arguments = if keyword_arguments
            # This is a little crazy. We expect the `:argument_details` extra to _include extras_,
            # but the object isn't created until _after_ extras are put together.
            # So, we have to use a special flag here to say, "at the last minute, add yourself to the keyword args."
            #
            # Otherwise:
            # - We can't access the final Arguments instance _while_ we're preparing extras
            # - After we _can_ access it, it's frozen, so we can't add anything.
            #
            # So, this flag gives us a chance to sneak it in before freezing, _and_ while we have access
            # to the new Arguments instance itself.
            if keyword_arguments[:argument_details] == :__arguments_add_self
              keyword_arguments[:argument_details] = self
            end
            keyword_arguments.freeze
          elsif @empty
            NO_ARGS
          else
            nil
          end
          @argument_values = argument_values ? argument_values.freeze : NO_ARGS
          @argument_values.each_value { |v| v.arguments = self }
          # freeze TODO put this call elsewhere?
        end

        # @return [Hash{Symbol => ArgumentValue}]
        attr_reader :argument_values

        def wait_until_dataloaded
          @argument_values.each_value do |arg_value|
            @context.dataloader.append_job(arg_value)
          end

          while !argument_values.each_value.all?(&:completed?)
            @context.dataloader.yield # TODO this is a hack to let those finish first
          end
          p [@parent_object]
          p argument_values.each_value.map(&:value)
          if (first_error = argument_values.each_value.find(&:errored?))
            first_error.value
          elsif @parent_object.is_a?(Class) && @parent_object < GraphQL::Schema::InputObject
            @parent_object.new(self, ruby_kwargs: keyword_arguments, context: @context, defaults_used: nil)
          else
            self
          end
        end

        def empty?
          @empty
        end

        # The Ruby-style arguments hash, ready for a resolver.
        # This hash is the one used at runtime.
        #
        # @return [Hash<Symbol, Object>]
        def keyword_arguments
          kws = {}
          argument_values.each do |name, arg_val|
            kws[name] = arg_val.value
          end
          if @keyword_arguments
            @keyword_arguments.merge(kws)
          else
            kws
          end
        end

        def_delegators :keyword_arguments, :key?, :[], :fetch, :keys, :each, :values, :size, :to_h
        def_delegators :argument_values, :each_value

        def inspect
          "#<#{self.class} @keyword_arguments=#{keyword_arguments.inspect}>"
        end

        # Create a new arguments instance which includes these extras.
        #
        # This is called by the runtime to implement field `extras: [...]`
        #
        # @param extra_args [Hash<Symbol => Object>]
        # @return [Interpreter::Arguments]
        # @api private
        def merge_extras(extra_args)
          self.class.new(
            argument_values: argument_values,
            keyword_arguments: keyword_arguments.merge(extra_args)
          )
        end

        NO_ARGS = GraphQL::EmptyObjects::EMPTY_HASH
        EMPTY = self.new(argument_values: nil, keyword_arguments: NO_ARGS).freeze
      end
    end
  end
end
