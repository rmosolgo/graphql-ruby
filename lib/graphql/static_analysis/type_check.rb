require "graphql/static_analysis/type_check/any_type"

module GraphQL
  module StaticAnalysis
    # This is responsible for several of the validations in the GraphQL spec:
    # - [ ] Field Selections on Objects, Interfaces, and Unions Types
    # - [ ] Field Selection Merging
    # - [ ] Leaf Field Selections
    # - [ ] Argument Names
    # - [ ] Argument Value Compatibility
    # - [ ] Required Arguments are Present
    # - [ ] Fragment Type Existence
    # - [ ] Fragments on Composite Types
    # - [ ] Fragment Spreads are Possible
    # - [ ] Object Spreads in Object Scope
    # - [ ] Abstract Spreads in Object Scope
    # - [ ] Object Spreads in Abstract Scope
    # - [ ] Abstract Spreads in Abstract Scope
    # - [ ] Directives are Defined
    # - [ ] Directives are in Valid Locations
    # - [ ] Variable Default Values are Correctly Typed
    # - [ ] Variables are Input Types
    # - [ ] Variable Usages are Allowed
    class TypeCheck
      include GraphQL::Language::Nodes

      def self.mount(visitor)
        type_checker = self.new
        type_checker.mount(visitor)
        type_checker
      end

      def initialize(analysis)
        @analysis = analysis
        @schema = analysis.schema # TODO: or AnySchema
      end

      def mount(visitor)
        visitor[OperationDefinition] << -> (node, prev_node) {

        }

        visitor[Field] << -> (node, prev_node) {

        }
      end
    end
  end
end
