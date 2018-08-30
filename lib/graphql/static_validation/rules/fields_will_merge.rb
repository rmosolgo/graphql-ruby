# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FieldsWillMerge
      NO_ARGS = {}.freeze

      def on_operation_definition(node, _parent)
        conflicts_within_selection_set(node, type_definition)
        super
      end

      def on_field(node, _parent)
        conflicts_within_selection_set(node, type_definition)
        super
      end

      private

      def conflicts_within_selection_set(node, type_definition)
        fields = find_fields(node.selections, parent_type: type_definition)
        fragment_names = find_fragment_names(node.selections)

        # (A) Find find all conflicts "within" the fields of this selection set.
        collect_conflicts_within(fields)
      end

      def collect_conflicts_within(response_keys)
        response_keys.each do |key, fields|
          next if fields.size < 2
          # find conflicts within nodes
          for i in 0..fields.size-1
            for j in i+1..fields.size-1
              find_conflict(key, fields[i], fields[j])
            end
          end
        end
      end

      def find_conflict(response_key, field1, field2, mutually_exclusive: false)
        parent_type_1 = field1[:parent_type]
        parent_type_2 = field2[:parent_type]

        node1 = field1[:node]
        node2 = field2[:node]

        are_mutually_exclusive = mutually_exclusive ||
                                 (parent_type_1 != parent_type_2 &&
                                  parent_type_1.kind.object? &&
                                  parent_type_2.kind.object?)

        if !are_mutually_exclusive
          if node1.name != node2.name
            msg = "Field '#{response_key}' has a field conflict: #{node1.name} or #{node2.name}?"
            context.errors << GraphQL::StaticValidation::Message.new(msg, nodes: [node1, node2])
          end

          args = possible_arguments(node1, node2)
          if args.size > 1
            msg = "Field '#{response_key}' has an argument conflict: #{args.map{ |arg| GraphQL::Language.serialize(arg) }.join(" or ")}?"
            context.errors << GraphQL::StaticValidation::Message.new(msg, nodes: [node1, node2])
          end
        end

        find_conflicts_between_sub_selection_sets(
          field1,
          field2,
          mutually_exclusive: are_mutually_exclusive
        )
      end

      def find_conflicts_between_sub_selection_sets(field1, field2, mutually_exclusive:)
        selections = field1[:node].selections
        selections2 = field2[:node].selections
        fields = find_fields(selections, parent_type: field1[:defn].type.unwrap )
        fields2 = find_fields(selections2, parent_type: field2[:defn].type.unwrap)
        fragment_names = find_fragment_names(selections)
        fragment_names_2 = find_fragment_names(selections2)

        collect_conflicts_between(fields, fields2, mutually_exclusive: mutually_exclusive)
      end

      def collect_conflicts_between(response_keys, response_keys_2, mutually_exclusive:)
        response_keys.each do |key, fields|
          fields2 = response_keys_2[key]
          if fields2
            fields.each do |field|
              fields2.each do |field2|
                find_conflict(
                  key,
                  field,
                  field2,
                  mutually_exclusive: mutually_exclusive
                )
              end
            end
          end
        end
      end

      def find_fields(selections, parent_type:)
        fields = selections.map do |node|
          case node
          when GraphQL::Language::Nodes::Field
            {
              node: node,
              parent_type: parent_type,
              defn: context.schema.get_field(parent_type, node.name)
            }
          when GraphQL::Language::Nodes::InlineFragment
            find_fields(node.selections, parent_type: node.type || parent_type)
          end
        end.flatten

        fields.group_by { |f| f[:node].alias || f[:node].name }
      end

      def find_fragment_names(selections)
        selections
          .select { |s| s.is_a?(GraphQL::Language::Nodes::FragmentSpread) }
          .map(&:name)
      end

      def possible_arguments(field1, field2)
        # Check for incompatible / non-identical arguments on this node:
        [field1, field2].map do |n|
          if n.arguments.any?
            n.arguments.reduce({}) do |memo, a|
              arg_value = a.value
              memo[a.name] = case arg_value
              when GraphQL::Language::Nodes::AbstractNode
                arg_value.to_query_string
              else
                GraphQL::Language.serialize(arg_value)
              end
              memo
            end
          else
            NO_ARGS
          end
        end.uniq
      end
    end
  end
end
