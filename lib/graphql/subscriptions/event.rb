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
      def self.serialize(_name, arguments, field, scope:)
        subscription = field.resolver || GraphQL::Schema::Subscription
        normalized_args = stringify_args(field, arguments.to_h)
        subscription.topic_for(arguments: normalized_args, field: field, scope: scope)
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
          arg_owner = arg_owner.respond_to?(:unwrap) ? arg_owner.unwrap : arg_owner # remove list and non-null wrappers
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
              arg_base_type = arg_defn.type.unwrap
              # In the case where the value being emitted is seen as a "JSON"
              # type, treat the value as one atomic unit of serialization
              is_json_definition = arg_base_type && arg_base_type <= GraphQL::Types::JSON
              if is_json_definition
                next_args[normalized_arg_name] = v.respond_to?(:to_json) ? v.to_json : v
              else
                next_args[normalized_arg_name] = stringify_args(arg_base_type, v)
              end


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
