# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      class Analyzer
        def initialize(query)
          @query = query
        end

        def analyze?
          true
        end

        def result
          raise NotImplementedError
        end

        # Don't use make_visit_method becuase it breaks `super`
        def self.build_visitor_hooks(member_name)
          class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def on_enter_#{member_name}(node, parent, visitor)
            end

            def on_leave_#{member_name}(node, parent, visitor)
            end
          EOS
        end

        build_visitor_hooks :argument
        build_visitor_hooks :directive
        build_visitor_hooks :directive_definition
        build_visitor_hooks :directive_location
        build_visitor_hooks :document
        build_visitor_hooks :enum
        build_visitor_hooks :enum_type_definition
        build_visitor_hooks :enum_type_extension
        build_visitor_hooks :enum_value_definition
        build_visitor_hooks :field
        build_visitor_hooks :field_definition
        build_visitor_hooks :fragment_definition
        build_visitor_hooks :fragment_spread
        build_visitor_hooks :inline_fragment
        build_visitor_hooks :input_object
        build_visitor_hooks :input_object_type_definition
        build_visitor_hooks :input_object_type_extension
        build_visitor_hooks :input_value_definition
        build_visitor_hooks :interface_type_definition
        build_visitor_hooks :interface_type_extension
        build_visitor_hooks :list_type
        build_visitor_hooks :non_null_type
        build_visitor_hooks :null_value
        build_visitor_hooks :object_type_definition
        build_visitor_hooks :object_type_extension
        build_visitor_hooks :operation_definition
        build_visitor_hooks :scalar_type_definition
        build_visitor_hooks :scalar_type_extension
        build_visitor_hooks :schema_definition
        build_visitor_hooks :schema_extension
        build_visitor_hooks :type_name
        build_visitor_hooks :union_type_definition
        build_visitor_hooks :union_type_extension
        build_visitor_hooks :variable_definition
        build_visitor_hooks :variable_identifier
        build_visitor_hooks :abstract_node

        protected

        attr_reader :query
      end
    end
  end
end
