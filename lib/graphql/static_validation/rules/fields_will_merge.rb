module GraphQL
  module StaticValidation
    class FieldsWillMerge
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
            find_conflicts(field_map, [], context)
          }
        }
      end

      private

      def find_conflicts(field_map, visited_fragments, context)
        field_map.each do |name, ast_fields|
          comparison = FieldDefinitionComparison.new(name, ast_fields, context)
          context.errors.push(*comparison.errors)


          subfield_map = {}
          ast_fields.each do |defn|
            gather_fields_by_name(defn.selections, subfield_map, visited_fragments, context)
          end

          find_conflicts(subfield_map, visited_fragments, context)
        end
      end

      def gather_fields_by_name(fields, field_map, visited_fragments, context)
        fields.each do |field|
          case field
          when GraphQL::Language::Nodes::InlineFragment
            next_fields = field.selections
          when GraphQL::Language::Nodes::FragmentSpread
            if visited_fragments.include?(field.name)
              next
            else
              visited_fragments << field.name
            end
            fragment_defn = context.fragments[field.name]
            next_fields = fragment_defn ? fragment_defn.selections : []
          when GraphQL::Language::Nodes::Field
            name_in_selection = field.alias || field.name
            field_map[name_in_selection] ||= []
            field_map[name_in_selection].push(field)
            next_fields = []
          else
            raise "Unexpected field for merging: #{field}"
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
        def initialize(name, defs, context)
          errors = []

          names = defs.map(&:name).uniq
          if names.length != 1
            errors << message("Field '#{name}' has a field conflict: #{names.join(" or ")}?", defs.first, context: context)
          end

          args = defs.map { |defn| reduce_list(defn.arguments)}.uniq
          if args.length != 1
            errors << message("Field '#{name}' has an argument conflict: #{args.map {|a| JSON.dump(a) }.join(" or ")}?", defs.first, context: context)
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
  end
end
