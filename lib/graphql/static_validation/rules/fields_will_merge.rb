# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FieldsWillMerge
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        fragments = {}
        has_selections = []
        visitor = context.visitor
        visitor[GraphQL::Language::Nodes::OperationDefinition] << ->(node, parent) {
          if node.selections.any?
            has_selections << node
          end
        }
        visitor[GraphQL::Language::Nodes::Document].leave << ->(node, parent) {
          has_selections.each { |node|
            field_map = gather_fields_by_name(node.selections, {}, [], context)
            find_conflicts(field_map, [], context)
          }
        }
      end

      private

      def find_conflicts(field_map, visited_fragments, context)
        field_map.each do |name, ast_fields|
          errs = compare_fields(name, ast_fields, context)
          context.errors.concat(errs)

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
      def compare_fields(name, ast_fields, context)
        errors = []

        names = ast_fields.map(&:name).uniq
        if names.length != 1
          errors << message("Field '#{name}' has a field conflict: #{names.join(" or ")}?", ast_fields.first, context: context)
        end

        args = ast_fields.map { |ast_node| field_args_string(ast_node) }.uniq
        if args.length != 1
          errors << message("Field '#{name}' has an argument conflict: #{args.map{ |arg| GraphQL::Language.serialize(arg) }.join(" or ")}?", ast_fields.first, context: context)
        end

        errors
      end

      def field_args_string(ast_field)
        ast_field.arguments.each_with_object({}) do |arg, memo|
          memo[arg.name] = GraphQL::Language::Generation.generate(arg.value)
        end
      end
    end
  end
end
