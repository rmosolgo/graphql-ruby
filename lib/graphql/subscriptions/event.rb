# frozen_string_literal: true
module GraphQL
  class Subscriptions
    # This thing can be:
    # - Subscribed to by `subscription { ... }`
    # - Triggered by `MySchema.subscriber.trigger(name, arguments, obj)`
    #
    class Event
      # @return [String] Corresponds to the Subscription root field name
      attr_reader :name

      # @return [GraphQL::Query::Arguments]
      attr_reader :arguments

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # @return [String] An opaque string which identifies this event, derived from `name` and `arguments`
      attr_reader :topic

      def initialize(name:, arguments:, field: nil, context: nil, scope: nil)
        @name = name
        @arguments = arguments
        @context = context
        field ||= context.field
        scope_val = scope || (context && field.subscription_scope && context[field.subscription_scope])

        @topic = self.class.serialize(name, arguments, field, scope: scope_val)
      end

      # @return [String] an identifier for this unit of subscription
      def self.serialize(name, arguments, field, scope:)
        normalized_args = case arguments
        when GraphQL::Query::Arguments
          arguments
        when Hash
          if field.is_a?(GraphQL::Schema::Field)
            stringify_args(field, arguments)
          else
            GraphQL::Query::LiteralInput.from_arguments(
              arguments,
              field,
              nil,
            )
          end
        else
          raise ArgumentError, "Unexpected arguments: #{arguments}, must be Hash or GraphQL::Arguments"
        end

        sorted_h = stringify_args(field, normalized_args.to_h)
        Serialize.dump_recursive([scope, name, sorted_h])
      end

      # @return [String] a logical identifier for this event. (Stable when the query is broadcastable.)
      def fingerprint
        @fingerprint ||= begin
          # When this query has been flagged as broadcastable,
          # use a generalized, stable fingerprint so that
          # duplicate subscriptions can be evaluated and distributed in bulk.
          # (`@topic` includes field, args, and subscription scope already.)
          if @context.namespace(:subscriptions)[:subscription_broadcastable]
            "#{@topic}/#{@context.query.fingerprint}"
          else
            # not broadcastable, build a unique ID for this event
            @context.schema.subscriptions.build_id
          end
        end
      end

      class << self
        private
        def stringify_args(arg_owner, args)
          case args
          when Hash
            next_args = {}
            args.each do |k, v|
              arg_name = k.to_s
              camelized_arg_name = GraphQL::Schema::Member::BuildType.camelize(arg_name)
              arg_defn = get_arg_definition(arg_owner, camelized_arg_name)

              if arg_defn
                normalized_arg_name = camelized_arg_name
              else
                normalized_arg_name = arg_name
                arg_defn = get_arg_definition(arg_owner, normalized_arg_name)
              end

              next_args[normalized_arg_name] = stringify_args(arg_defn.type, v)
            end
            # Make sure they're deeply sorted
            next_args.sort.to_h
          when Array
            args.map { |a| stringify_args(arg_owner, a) }
          when GraphQL::Schema::InputObject
            stringify_args(arg_owner, args.to_h)
          else
            args
          end
        end

        def get_arg_definition(arg_owner, arg_name)
          arg_owner.arguments[arg_name] || arg_owner.arguments.each_value.find { |v| v.keyword.to_s == arg_name }
        end
      end
    end
  end
end
