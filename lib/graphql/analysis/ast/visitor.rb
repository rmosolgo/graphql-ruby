# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      # Depth first traversal through a query AST, calling AST analyzers
      # along the way.
      #
      # The visitor is a special case of GraphQL::Language::Visitor, visiting
      # only the selected operation, providing helpers for common use cases such
      # as skipped fields and visiting fragment spreads.
      #
      # @see {GraphQL::Analysis::AST::Analyzer} AST Analyzers for queries
      class Visitor < GraphQL::Language::Visitor
        def initialize(query:, analyzers:)
          @analyzers = analyzers
          @path = []
          @object_types = []
          @directives = []
          @field_definitions = []
          @argument_definitions = []
          @directive_definitions = []
          @rescued_errors = []
          @query = query
          @schema = query.schema
          @response_path = []
          @skip_stack = [false]
          super(query.selected_operation)
        end

        # @return [GraphQL::Query] the query being visited
        attr_reader :query

        # @return [Array<GraphQL::ObjectType>] Types whose scope we've entered
        attr_reader :object_types

        # @return [Array<GraphQL::AnalysisError]
        attr_reader :rescued_errors

        def visit
          return unless @document
          super
        end

        # Visit Helpers

        # @return [GraphQL::Query::Arguments] Arguments for this node, merging default values, literal values and query variables
        # @see {GraphQL::Query#arguments_for}
        def arguments_for(ast_node, field_definition)
          @query.arguments_for(ast_node, field_definition)
        end

        # @return [Boolean] If the visitor is currently inside a fragment definition
        def visiting_fragment_definition?
          @in_fragment_def
        end

        # @return [Boolean] If the current node should be skipped because of a skip or include directive
        def skipping?
          @skipping
        end

        # @return [Array<String>] The path to the response key for the current field
        def response_path
          @response_path.dup
        end

        # Visitor Hooks

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
            @in_fragment_def = false
            call_analyzers(:on_enter_fragment_definition, node, parent)
            super
            @in_fragment_def = false
            call_analyzers(:on_leave_fragment_definition, node, parent)
          end
        end

        def on_inline_fragment(node, parent)
          on_fragment_with_type(node) do
            @path.push("...#{node.type ? " on #{node.type.name}" : ""}")
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

          @skipping = @skip_stack.last || skip?(node)
          @skip_stack << @skipping

          call_analyzers(:on_enter_field, node, parent)
          super

          @skipping = @skip_stack.pop

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
              arg_type.arguments[node.name]
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
          enter_fragment_spread_inline(node)
          super
          leave_fragment_spread_inline(node)
          call_analyzers(:on_leave_fragment_spread, node, parent)
          @path.pop
        end

        def on_abstract_node(node, parent)
          call_analyzers(:on_enter_abstract_node, node, parent)
          super
          call_analyzers(:on_leave_abstract_node, node, parent)
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

        # @return [GraphQL::Field, nil] The GraphQL field which returned the object that the current field belongs to
        def previous_field_definition
          @field_definitions[-2]
        end

        # @return [GraphQL::Directive, nil] The most-recently-entered GraphQL::Directive, if currently inside one
        def directive_definition
          @directive_definitions.last
        end

        # @return [GraphQL::Argument, nil] The most-recently-entered GraphQL::Argument, if currently inside one
        def argument_definition
          @argument_definitions.last
        end

        # @return [GraphQL::Argument, nil] The previous GraphQL argument
        def previous_argument_definition
          @argument_definitions[-2]
        end

        private

        # Visit a fragment spread inline instead of visiting the definition
        # by itself.
        def enter_fragment_spread_inline(fragment_spread)
          fragment_def = query.fragments[fragment_spread.name]

          object_type = if fragment_def.type
            @query.warden.get_type(fragment_def.type.name)
          else
            object_types.last
          end

          object_types << object_type

          fragment_def.selections.each do |selection|
            visit_node(selection, fragment_def)
          end
        end

        # Visit a fragment spread inline instead of visiting the definition
        # by itself.
        def leave_fragment_spread_inline(_fragment_spread)
          object_types.pop
        end

        def skip?(ast_node)
          dir = ast_node.directives
          dir.any? && !GraphQL::Execution::DirectiveChecks.include?(dir, query)
        end

        def call_analyzers(method, node, parent)
          @analyzers.each do |analyzer|
            begin
              analyzer.public_send(method, node, parent, self)
            rescue AnalysisError => err
              @rescued_errors << err
            end
          end
        end

        def on_fragment_with_type(node)
          object_type = if node.type
            @query.warden.get_type(node.type.name)
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
