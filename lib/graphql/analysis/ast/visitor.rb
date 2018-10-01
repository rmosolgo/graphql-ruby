# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      class Visitor < GraphQL::Language::Visitor
        def initialize(query:, analyzers:)
          @analyzers = analyzers
          @path = []
          @object_types = []
          @directives = []
          @field_definitions = []
          @argument_definitions = []
          @directive_definitions = []
          @query = query
          @schema = query.schema
          @response_path = []
          super(query.document)
        end

        attr_reader :context, :query

        # @return [Array<GraphQL::ObjectType>] Types whose scope we've entered
        attr_reader :object_types

        # @return [Array<String>] The nesting of the current position in the AST
        def path
          @path.dup
        end

        def arguments_for(ast_node, field_definition)
          @query.arguments_for(ast_node, field_definition)
        end

        def on_operation_definition(node, parent)
          object_type = @schema.root_type_for_operation(node.operation_type)
          @object_types.push(object_type)
          @path.push("#{node.operation_type}#{node.name ? " #{node.name}" : ""}")
          call_analyzers(:on_enter_operation_definition, node, parent)
          super
          call_analyzers(:on_leave_operation_definition, node, parent)
          @object_types.pop
          @path.pop
        end

        def on_fragment_definition(node, parent)
          on_fragment_with_type(node) do
            @path.push("fragment #{node.name}")
            call_analyzers(:on_enter_fragment_definition, node, parent)
            super
            call_analyzers(:on_leave_fragment_definition, node, parent)
          end
        end

        def on_inline_fragment(node, parent)
          on_fragment_with_type(node) do
            @path.push("...#{node.type ? " on #{node.type.to_query_string}" : ""}")
            call_analyzers(:on_enter_inline_fragment, node, parent)
            super
            call_analyzers(:on_leave_inline_fragment, node, parent)
          end
        end

        def on_field(node, parent)
          @response_path.push(node.alias || node.name)
          parent_type = @object_types.last
          field_definition = @schema.get_field(parent_type, node.name)
          @field_definitions.push(field_definition)
          if !field_definition.nil?
            next_object_type = field_definition.type.unwrap
            @object_types.push(next_object_type)
          else
            @object_types.push(nil)
          end
          @path.push(node.alias || node.name)
          call_analyzers(:on_enter_field, node, parent)
          super
          call_analyzers(:on_leave_field, node, parent)
          @response_path.pop
          @field_definitions.pop
          @object_types.pop
          @path.pop
        end

        def on_directive(node, parent)
          directive_defn = @schema.directives[node.name]
          @directive_definitions.push(directive_defn)
          call_analyzers(:on_enter_directive, node, parent)
          super
          call_analyzers(:on_leave_directive, node, parent)
          @directive_definitions.pop
        end

        def on_argument(node, parent)
          argument_defn = if (arg = @argument_definitions.last)
            arg_type = arg.type.unwrap
            if arg_type.kind.input_object?
              arg_type.input_fields[node.name]
            else
              nil
            end
          elsif (directive_defn = @directive_definitions.last)
            directive_defn.arguments[node.name]
          elsif (field_defn = @field_definitions.last)
            field_defn.arguments[node.name]
          else
            nil
          end

          @argument_definitions.push(argument_defn)
          @path.push(node.name)
          call_analyzers(:on_enter_argument, node, parent)
          super
          call_analyzers(:on_leave_argument, node, parent)
          @argument_definitions.pop
          @path.pop
        end

        def on_fragment_spread(node, parent)
          @path.push("... #{node.name}")
          call_analyzers(:on_enter_fragment_spread, node, parent)
          super
          call_analyzers(:on_leave_fragment_spread, node, parent)
          @path.pop
        end

        def on_abstract_node(node, parent)
          call_analyzers(:on_enter_abstract_node, node, parent)
          super
          call_analyzers(:on_leave_abstract_node, node, parent)
        end

        def response_path
          @response_path.dup
        end

        # @return [GraphQL::BaseType] The current object type
        def type_definition
          @object_types.last
        end

        # @return [GraphQL::BaseType] The type which the current type came from
        def parent_type_definition
          @object_types[-2]
        end

        # @return [GraphQL::Field, nil] The most-recently-entered GraphQL::Field, if currently inside one
        def field_definition
          @field_definitions.last
        end

        # @return [GraphQL::Directive, nil] The most-recently-entered GraphQL::Directive, if currently inside one
        def directive_definition
          @directive_definitions.last
        end

        # @return [GraphQL::Argument, nil] The most-recently-entered GraphQL::Argument, if currently inside one
        def argument_definition
          # Don't get the _last_ one because that's the current one.
          # Get the second-to-last one, which is the parent of the current one.
          @argument_definitions[-2]
        end

        private

        def call_analyzers(method, node, parent)
          @analyzers.each do |analyzer|
            analyzer.public_send(method, node, parent, self)
          end
        end

        def on_fragment_with_type(node)
          object_type = if node.type
            @schema.types.fetch(node.type.name, nil)
          else
            @object_types.last
          end
          @object_types.push(object_type)
          yield(node)
          @object_types.pop
          @path.pop
        end
      end
    end
  end
end
