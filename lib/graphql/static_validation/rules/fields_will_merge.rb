class GraphQL::StaticValidation::FieldsWillMerge
  def validate(context)
    fragments = {}
    has_selections = []
    visitor = context.visitor
    visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, parent) {
      if node.selections.any?
        has_selections << node
      end
    }
    visitor[GraphQL::Language::Nodes::Document].leave << -> (node, parent) {
      has_selections.each { |node|
        field_map = gather_fields_by_name(node.selections, {}, [], context)
        find_conflicts(field_map, context)
      }
    }
  end

  private

  def find_conflicts(field_map, context)
    field_map.each do |name, ast_fields|
      comparison = FieldDefinitionComparison.new(name, ast_fields)
      context.errors.push(*comparison.errors)


      subfield_map = {}
      visited_fragments = []
      ast_fields.each do |defn|
        gather_fields_by_name(defn.selections, subfield_map, visited_fragments, context)
      end
      find_conflicts(subfield_map, context)
    end
  end

  def gather_fields_by_name(fields, field_map, visited_fragments, context)
    fields.each do |field|
      if field.is_a?(GraphQL::Language::Nodes::InlineFragment)
        next_fields = field.selections
      elsif field.is_a?(GraphQL::Language::Nodes::FragmentSpread)
        if visited_fragments.include?(field.name)
          next
        else
          visited_fragments << field.name
        end
        fragment_defn = context.fragments[field.name]
        next_fields = fragment_defn ? fragment_defn.selections : []
      else
        name_in_selection = field.alias || field.name
        field_map[name_in_selection] ||= []
        field_map[name_in_selection].push(field)
        next_fields = []
      end
      gather_fields_by_name(next_fields, field_map, visited_fragments, context)
    end
    field_map
  end

  # Compare two field definitions, add errors to the list if there are any
  class FieldDefinitionComparison
    include GraphQL::StaticValidation::Message::MessageHelper
    NAMED_VALUES = [GraphQL::Language::Nodes::Enum, GraphQL::Language::Nodes::VariableIdentifier]
    attr_reader :errors
    def initialize(name, defs)
      errors = []

      names = defs.map(&:name).uniq
      if names.length != 1
        errors << message("Field '#{name}' has a field conflict: #{names.join(" or ")}?", defs.first)
      end

      args = defs.map { |defn| reduce_list(defn.arguments)}.uniq
      if args.length != 1
        errors << message("Field '#{name}' has an argument conflict: #{args.map {|a| JSON.dump(a) }.join(" or ")}?", defs.first)
      end

      directive_names = defs.map { |defn| defn.directives.map(&:name) }.uniq
      if directive_names.length != 1
        errors << message("Field '#{name}' has a directive conflict: #{directive_names.map {|names| "[#{names.join(", ")}]"}.join(" or ")}?", defs.first)
      end

      directive_args = defs.map {|defn| defn.directives.map {|d| reduce_list(d.arguments) } }.uniq
      if directive_args.length != 1
        errors << message("Field '#{name}' has a directive argument conflict: #{directive_args.map {|args| JSON.dump(args)}.join(" or ")}?", defs.first)
      end

      @errors = errors
    end

    private

    # Turn AST tree into a hash
    # can't look up args, the names just have to match
    def reduce_list(args)
      args.reduce({}) do |memo, a|
        memo[a.name] = NAMED_VALUES.include?(a.value.class) ? a.value.name : a.value
        memo
      end
    end
  end
end
