# The problem is
#   - Variable usage must be determined at the OperationDefinition level
#   - You can't tell how fragments use variables until you visit FragmentDefinitions (which may be at the end of the document)
#
#  So, this validator includes some crazy logic to follow fragment spreads recursively, while avoiding infinite loops.
#
# `graphql-js` solves this problem by:
#   - re-visiting the AST for each validator
#   - allowing validators to say `followSpreads: true`
#
class GraphQL::StaticValidation::VariablesAreUsedAndDefined
  include GraphQL::StaticValidation::Message::MessageHelper

  class VariableUsage
    attr_accessor :ast_node
    attr_reader :declared, :used
    alias :used? :used
    alias :declared? :declared

    def declared_by(op_def_node)
      @declared = op_def_node
    end

    def used_by(context_node)
      @used = context_node
    end

    def used_but_not_declared?
      used? && !declared?
    end

    def declared_but_not_used?
      declared? && !used?
    end
  end

  def variable_hash
    Hash.new {|h, k| h[k] = VariableUsage.new }
  end

  def validate(context)
    variable_usages_for_context = Hash.new {|hash, key| hash[key] = variable_hash }
    spreads_for_context = Hash.new {|hash, key| hash[key] = [] }
    variable_context_stack = []

    # For OperationDefinitions:
    #   - initialize a usage hash
    #   - mark some vars as defined
    #   - push the context on the stack (then pop in on leave)
    context.visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, parent) {
      var_hash = variable_usages_for_context[node]
      declared_variables = node.variables.each_with_object(var_hash) { |var, memo| memo[var.name].declared_by(node) }
      variable_context_stack.push(node)
    }

    context.visitor[GraphQL::Language::Nodes::OperationDefinition].leave << -> (node, parent) {
      variable_context_stack.pop
    }

    # For FragmentDefinitions:
    #   - initialize a usage hash
    #   - push the context on the stack (then pop in on leave)
    context.visitor[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, parent) {
      variable_usages_for_context[node] # initialize the hash
      variable_context_stack.push(node)
    }
    context.visitor[GraphQL::Language::Nodes::FragmentDefinition].leave << -> (node, parent) {
      variable_context_stack.pop
    }

    # For FragmentSpreads:
    #  - find the context on the stack
    #  - mark the context as containing this spread
    context.visitor[GraphQL::Language::Nodes::FragmentSpread] << -> (node, parent) {
      variable_context = variable_context_stack.last
      spreads_for_context[variable_context] << node.name
    }

    # For VariableIdentifiers:
    #  - mark the variable as used
    #  - assign its AST node
    context.visitor[GraphQL::Language::Nodes::VariableIdentifier] << -> (node, parent) {
      usage_context = variable_context_stack.last
      declared_variables = variable_usages_for_context[usage_context]
      usage = declared_variables[node.name]
      usage.used_by(usage_context)
      usage.ast_node = node
    }


    context.visitor[GraphQL::Language::Nodes::Document].leave << -> (node, parent) {
      fragment_definitions = variable_usages_for_context.select { |key, value| key.is_a?(GraphQL::Language::Nodes::FragmentDefinition) }
      operation_definitions = variable_usages_for_context.select { |key, value| key.is_a?(GraphQL::Language::Nodes::OperationDefinition) }

      operation_definitions.each do |node, node_variables|
        follow_spreads(node, node_variables, spreads_for_context, fragment_definitions, [])

        node_variables
          .select { |name, usage| usage.declared_but_not_used? }
          .each { |var_name, usage|
            context.errors << message("Variable $#{var_name} is declared by #{usage.declared.name} but not used", usage.declared)
          }

        node_variables
          .select { |name, usage| usage.used_but_not_declared? }
          .each { |var_name, usage|
            context.errors << message("Variable $#{var_name} is used by #{usage.used.name} but not declared", usage.ast_node)
          }
      end
    }
  end


  # Follow spreads in `node`, looking them up from `spreads_for_context` and finding their match in `fragment_definitions`.
  # Use those fragments to update {VariableUsage}s in `parent_variables`.
  # Avoid infinite loops by skipping anything in `visited_fragments`.
  def follow_spreads(node, parent_variables, spreads_for_context, fragment_definitions, visited_fragments)
    spreads = spreads_for_context[node] - visited_fragments
    spreads.each do |spread_name|
      def_node, variables = fragment_definitions.find { |def_node, vars| def_node.name == spread_name }
      next if !def_node
      visited_fragments << spread_name
      variables.each do |name, child_usage|
        parent_usage = parent_variables[name]
        if child_usage.used?
          parent_usage.ast_node  = child_usage.ast_node
          parent_usage.used_by(child_usage.used)
        end
      end
      follow_spreads(def_node, parent_variables, spreads_for_context, fragment_definitions, visited_fragments)
    end
  end

end
