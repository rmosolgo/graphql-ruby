# frozen_string_literal: true

module GraphQL
  module Tracing
    # Each platform provides:
    # - `.platform_keys`
    # - `#platform_trace`
    # - `#platform_field_key(type, field)`
    # @api private
    class PlatformTracing
      class << self
        attr_accessor :platform_keys
      end

      def initialize
        @platform_keys = self.class.platform_keys
      end

      def trace(key, data)
        case key
        when "lex", "parse", "validate", "analyze_query", "analyze_multiplex", "execute_query", "execute_query_lazy", "execute_multiplex"
          platform_key = @platform_keys.fetch(key)
          platform_trace(platform_key, key, data) do
            yield
          end
        when "execute_field", "execute_field_lazy"
          if (platform_key = data[:context].field.metadata[:platform_key])
            platform_trace(platform_key, key, data) do
              yield
            end
          else
            yield
          end
        else
          # it's a custom key
          yield
        end
      end

      def instrument(type, field)
        return_type = field.type.unwrap
        case return_type
        when GraphQL::ScalarType, GraphQL::EnumType
          field
        else
          new_f = field.redefine
          new_f.metadata[:platform_key] = platform_field_key(type, field)
          new_f
        end
      end

      def self.use(schema_defn)
        tracer = self.new
        schema_defn.instrument(:field, tracer)
        schema_defn.tracer(tracer)
      end
    end
  end
end
