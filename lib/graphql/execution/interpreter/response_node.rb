# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class ResponseNode
        # @return [Class] A GraphQL type
        attr_accessor :static_type

        attr_accessor :dynamic_type

        # @return [Object] The return value from the field
        attr_accessor :ruby_value
        # @return [Object] The coerced, GraphQL-ready value. A hash if there are subselection
        attr_reader :graphql_value

        # @return [GraphQL::Language::Nodes::AbstractNode]
        attr_accessor :ast_node

        # @return [GraphQL::Execution::Interpreter::Trace]
        attr_reader :trace

        # @return [Boolean] True if an invalid null caused this to be left out
        def omitted?
          @omitted
        end

        attr_writer :omitted

        def initialize(trace:, parent:)
          # Maybe changed because of lazy:
          @trace = trace
          @parent = parent
          @static_type = nil
          @dynamic_type = nil
          @ruby_value = nil
          @ruby_value_was_set = false
          @ast_node = nil
          @graphql_value = nil
          @omitted = false
        end

        def write(value)
          if value.nil? && @static_type.non_null? && @parent
            @parent.write(nil)
          end
          @graphql_value = value
        end

        def call_ruby_value
          if !@ruby_value_was_set
            @ruby_value_was_set = true
            v = yield
            @ruby_value = v
          end
        end

        def ruby_value=(v)
          @ruby_value_was_set = true
          @ruby_value = v
        end

        def get_part(part)
          if @graphql_value.nil?
            nil
          else
            @graphql_value[part] ||= ResponseNode.new(trace: @trace, parent: self)
          end
        end

        def after_lazy
          @trace.after_lazy(@ruby_value) do |inner_trace, inner_ruby_value|
            @trace = inner_trace
            @ruby_value = inner_ruby_value
            yield
          end
        end

        def to_result
          case @graphql_value
          when Array
            @graphql_value.map { |v| v.is_a?(ResponseNode) ? v.to_result : v }
          when Hash
            r = {}
            @graphql_value.each do |k, v|
              if v.is_a?(ResponseNode) && !v.omitted?
                r[k] = v.to_result
              else
                # TODO is this ever called?
                r[k] = v
              end
            end
            r
          else
            @graphql_value
          end
        end
      end
    end
  end
end
