# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module GraphQL
      module Tracers
        # GraphQLTracer contains the OpenTelemetry tracer implementation compatible with
        # the GraphQL tracer API
        class GraphQLTracer < ::GraphQL::Tracing::PlatformTracing
          self.platform_keys = {
            'lex' => 'graphql.lex',
            'parse' => 'graphql.parse',
            'validate' => 'graphql.validate',
            'analyze_query' => 'graphql.analyze_query',
            'analyze_multiplex' => 'graphql.analyze_multiplex',
            'execute_query' => 'graphql.execute_query',
            'execute_query_lazy' => 'graphql.execute_query_lazy',
            'execute_multiplex' => 'graphql.execute_multiplex'
          }

          def platform_trace(platform_key, key, data)
            return yield if platform_key.nil?

            tracer.in_span(platform_key, attributes: attributes_for(key, data)) do |span|
              yield.tap do |response|
                errors = response[:errors]&.compact&.map { |e| e.to_h }&.to_json if key == 'validate'
                unless errors.nil?
                  span.add_event(
                    'graphql.validation.error',
                    attributes: {
                      'message' => errors
                    }
                  )
                end
              end
            end
          end

          def platform_field_key(type, field, context) # TODO: pass in context
            # If global setting is not enabled, return nil such that nothing is traced
            return unless config[:enable_platform_field]

            # If context setting is not set or enabled, return nil such that nothing is traced
            ns = context.namespace(:opentelemetry)
            return unless ns.key?(:enable_platform_field) && ns[:enable_platform_field]

            # Otherwise this is the key
            "#{type.graphql_name}.#{field.graphql_name}"
          end

          def platform_authorized_key(type, context) # TODO: pass in context
            return unless config[:enable_platform_authorized]

            # If context setting is not set or enabled, return nil such that nothing is traced
            ns = context.namespace(:opentelemetry)
            return unless ns.key?(:enable_platform_field) && ns[:enable_platform_authorized]

            "#{type.graphql_name}.authorized"
          end

          def platform_resolve_type_key(type, context) # TODO: pass in context
            return unless config[:enable_platform_resolve_type]

            # If context setting is not set or enabled, return nil such that nothing is traced
            ns = context.namespace(:opentelemetry)
            return unless ns.key?(:enable_platform_field) && ns[:enable_platform_resolve_type]

            "#{type.graphql_name}.resolve_type"
          end

          private

          def tracer
            GraphQL::Instrumentation.instance.tracer
          end

          def config
            GraphQL::Instrumentation.instance.config
          end

          def attributes_for(key, data)
            attributes = {}
            case key
            when 'execute_query'
              attributes['selected_operation_name'] = data[:query].selected_operation_name if data[:query].selected_operation_name
              attributes['selected_operation_type'] = data[:query].selected_operation.operation_type
              attributes['query_string'] = data[:query].query_string
            end
            attributes
          end

          def cached_platform_key(ctx, key, key_type) # key_type is one of :field, :authorized, :resolve_type
            cache = ctx.namespace(self.class)[:platform_key_cache] ||= {}
            # cache.fetch(key) { cache[key] = yield }
            cache.fetch(key) begin
              cache[key] = if key_type == :field
                platform_field_key(data[:owner], field, ctx)
              end
            end
          end
        end
      end
    end
  end
end