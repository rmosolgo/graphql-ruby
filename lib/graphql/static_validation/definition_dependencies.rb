# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Track fragment dependencies for operations
    # and expose the fragment definitions which
    # are used by a given operation
    class DefinitionDependencies
      def self.mount(visitor)
        deps = self.new
        deps.mount(visitor)
        deps
      end

      def initialize
        @node_paths = {}

        # { name => node } pairs for fragments
        @fragment_definitions = {}

        # This tracks dependencies from fragment to Node where it was used
        # { fragment_definition_node => [dependent_node, dependent_node]}
        @dependent_definitions = Hash.new { |h, k| h[k] = Set.new }

        # First-level usages of spreads within definitions
        # (When a key has an empty list as its value,
        #  we can resolve that key's depenedents)
        # { definition_node => [node, node ...] }
        @immediate_dependencies = Hash.new { |h, k| h[k] = Set.new }
      end

      # A map of operation definitions to an array of that operation's dependencies
      # @return [DependencyMap]
      def dependency_map(&block)
        @dependency_map ||= resolve_dependencies(&block)
      end

      def mount(context)
        visitor = context.visitor
        # When we encounter a spread,
        # this node is the one who depends on it
        current_parent = nil

        visitor[GraphQL::Language::Nodes::Document] << ->(node, prev_node) {
          node.definitions.each do |definition|
            case definition
            when GraphQL::Language::Nodes::OperationDefinition
            when GraphQL::Language::Nodes::FragmentDefinition
              @fragment_definitions[definition.name] = definition
            end
          end
        }

        visitor[GraphQL::Language::Nodes::OperationDefinition] << ->(node, prev_node) {
          @node_paths[node] = NodeWithPath.new(node, context.path)
          current_parent = node
        }

        visitor[GraphQL::Language::Nodes::OperationDefinition].leave << ->(node, prev_node) {
          current_parent = nil
        }

        visitor[GraphQL::Language::Nodes::FragmentDefinition] << ->(node, prev_node) {
          @node_paths[node] = NodeWithPath.new(node, context.path)
          current_parent = node
        }

        visitor[GraphQL::Language::Nodes::FragmentDefinition].leave << ->(node, prev_node) {
          current_parent = nil
        }

        visitor[GraphQL::Language::Nodes::FragmentSpread] << ->(node, prev_node) {
          @node_paths[node] = NodeWithPath.new(node, context.path)

          # Track both sides of the dependency
          @dependent_definitions[@fragment_definitions[node.name]] << current_parent
          @immediate_dependencies[current_parent] << node
        }
      end

      # Map definition AST nodes to the definition AST nodes they depend on.
      # Expose circular depednencies.
      class DependencyMap
        # @return [Array<GraphQL::Language::Nodes::FragmentDefinition>]
        attr_reader :cyclical_definitions

        # @return [Hash<Node, Array<GraphQL::Language::Nodes::FragmentSpread>>]
        attr_reader :unmet_dependencies

        # @return [Array<GraphQL::Language::Nodes::FragmentDefinition>]
        attr_reader :unused_dependencies

        def initialize
          @dependencies = Hash.new { |h, k| h[k] = [] }
          @cyclical_definitions = []
          @unmet_dependencies = Hash.new { |h, k| h[k] = [] }
          @unused_dependencies = []
        end

        # @return [Array<GraphQL::Language::Nodes::AbstractNode>] dependencies for `definition_node`
        def [](definition_node)
          @dependencies[definition_node]
        end
      end

      class NodeWithPath
        extend Forwardable
        attr_reader :node, :path
        def initialize(node, path)
          @node = node
          @path = path
        end

        def_delegators :@node, :name, :eql?, :hash
      end

      private

      # Return a hash of { node => [node, node ... ]} pairs
      # Keys are top-level definitions
      # Values are arrays of flattened dependencies
      def resolve_dependencies
        dependency_map = DependencyMap.new
        # Don't allow the loop to run more times
        # than the number of fragments in the document
        max_loops = @fragment_definitions.size
        loops = 0

        # Instead of tracking independent fragments _as you visit_,
        # determine them at the end. This way, we can treat fragments with the
        # same name as if they were the same name. If _any_ of the fragments
        # with that name has a dependency, we record it.
        independent_fragment_nodes = @fragment_definitions.values - @immediate_dependencies.keys

        while fragment_node = independent_fragment_nodes.pop
          loops += 1
          if loops > max_loops
            raise("Resolution loops exceeded the number of definitions; infinite loop detected.")
          end
          # Since it's independent, let's remove it from here.
          # That way, we can use the remainder to identify cycles
          @immediate_dependencies.delete(fragment_node)
          fragment_usages = @dependent_definitions[fragment_node]
          if fragment_usages.none?
            # If we didn't record any usages during the visit,
            # then this fragment is unused.
            dependency_map.unused_dependencies << @node_paths[fragment_node]
          else
            fragment_usages.each do |definition_node|
              # Register the dependency AND second-order dependencies
              dependency_map[definition_node] << fragment_node
              dependency_map[definition_node].concat(dependency_map[fragment_node])
              # Since we've regestered it, remove it from our to-do list
              deps = @immediate_dependencies[definition_node]
              # Can't find a way to _just_ delete from `deps` and return the deleted entries
              removed, remaining = deps.partition { |spread| spread.name == fragment_node.name }
              @immediate_dependencies[definition_node] = remaining
              if block_given?
                yield(definition_node, removed, fragment_node)
              end
              if remaining.none? && definition_node.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
                # If all of this definition's dependencies have
                # been resolved, we can now resolve its
                # own dependents.
                independent_fragment_nodes << definition_node
              end
            end
          end
        end

        # If any dependencies were _unmet_
        # (eg, spreads with no corresponding definition)
        # then they're still in there
        @immediate_dependencies.each do |defn_node, deps|
          deps.each do |spread|
            if @fragment_definitions[spread.name].nil?
              dependency_map.unmet_dependencies[@node_paths[defn_node]] << @node_paths[spread]
              deps.delete(spread)
            end
          end
          if deps.none?
            @immediate_dependencies.delete(defn_node)
          end
        end

        # Anything left in @immediate_dependencies is cyclical
        cyclical_nodes = @immediate_dependencies.keys.map { |n| @node_paths[n] }
        # @immediate_dependencies also includes operation names, but we don't care about
        # those. They became nil when we looked them up on `@fragment_definitions`, so remove them.
        cyclical_nodes.compact!
        dependency_map.cyclical_definitions.concat(cyclical_nodes)

        dependency_map
      end
    end
  end
end
