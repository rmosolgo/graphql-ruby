# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FieldsWillMerge
      NO_ARGS = {}.freeze

      def initialize(*)
        super
        @visited_fragments = {}
      end

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
        return if type_definition.nil?

        fields = response_keys_in_selection(node.selections, parent_type: type_definition)
        fragment_names = find_fragment_names(node.selections)

        # (A) Find find all conflicts "within" the fields of this selection set.
        find_conflicts_within(fields)

        fragment_names.each_with_index do |fragment_name, i|
          # (B) Then find conflicts between these fields and those represented by
          # each spread fragment name found.
          find_conflicts_between_fields_and_fragment(
            fragment_name,
            fields,
            mutually_exclusive: false
          )

          # (C) Then compare this fragment with all other fragments found in this
          # selection set to collect conflicts between fragments spread together.
          # This compares each item in the list of fragment names to every other
          # item in that same list (except for itself).
          fragment_names[i+1..-1].each do |fragment_name2|
            find_conflicts_between_fragments(
              fragment_name,
              fragment_name2,
              mutually_exclusive: false
            )
          end
        end
      end

      def find_conflicts_between_fragments(fragment_name1, fragment_name2, mutually_exclusive:)
        return if fragment_name1 == fragment_name2

        fragment1 = context.fragments[fragment_name1]
        fragment2 = context.fragments[fragment_name2]

        return if fragment1.nil? || fragment2.nil?

        fragment_type1 = context.schema.types[fragment1.type.name]
        fragment_type2 = context.schema.types[fragment2.type.name]

        return if fragment_type1.nil? || fragment_type2.nil?

        fragment_fields1 = response_keys_in_selection(fragment1.selections, parent_type: fragment_type1)
        fragment_names1 = find_fragment_names(fragment1.selections)

        fragment_fields2 = response_keys_in_selection(fragment2.selections, parent_type: fragment_type2)
        fragment_names2 = find_fragment_names(fragment2.selections)

        # (F) First, find all conflicts between these two collections of fields
        # (not including any nested fragments).
        find_conflicts_between(
          fragment_fields1,
          fragment_fields2,
          mutually_exclusive: mutually_exclusive
        )

        # (G) Then collect conflicts between the first fragment and any nested
        # fragments spread in the second fragment.
        fragment_names2.each do |fragment_name|
          find_conflicts_between_fragments(
            fragment_name1,
            fragment_name,
            mutually_exclusive: mutually_exclusive
          )
        end

        # (G) Then collect conflicts between the first fragment and any nested
        # fragments spread in the second fragment.
        fragment_names1.each do |fragment_name|
          find_conflicts_between_fragments(
            fragment_name1,
            fragment_name,
            mutually_exclusive: mutually_exclusive
          )
        end
      end

      def find_conflicts_between_fields_and_fragment(fragment_name, fields, mutually_exclusive:)
        return if @visited_fragments.key?(fragment_name)
        @visited_fragments[fragment_name] = true

        fragment = context.fragments[fragment_name]
        return if fragment.nil?

        fragment_type = context.schema.types[fragment.type.name]
        return if fragment_type.nil?

        fragment_fields = response_keys_in_selection(fragment.selections, parent_type: fragment_type)
        fragment_fragment_names = find_fragment_names(fragment.selections)

        # (D) First find any conflicts between the provided collection of fields
        # and the collection of fields represented by the given fragment.
        find_conflicts_between(
          fields,
          fragment_fields,
          mutually_exclusive: mutually_exclusive
        )

        # (E) Then collect any conflicts between the provided collection of fields
        # and any fragment names found in the given fragment.
        fragment_fragment_names.each do |fragment_name|
          find_conflicts_between_fields_and_fragment(
            fragment_name,
            fields,
            mutually_exclusive: mutually_exclusive
          )
        end
      end

      def find_conflicts_within(response_keys)
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
            errored_nodes = [node1.name, node2.name].sort.join(" or ")
            msg = "Field '#{response_key}' has a field conflict: #{errored_nodes}?"
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

        return if field1[:defn].nil? || field2[:defn].nil?

        fields = response_keys_in_selection(selections, parent_type: field1[:defn].type.unwrap)
        fields2 = response_keys_in_selection(selections2, parent_type: field2[:defn].type.unwrap)
        fragment_names = find_fragment_names(selections)
        fragment_names_2 = find_fragment_names(selections2)

        # (H) First, collect all conflicts between these two collections of field.
        find_conflicts_between(fields, fields2, mutually_exclusive: mutually_exclusive)

        # (I) Then collect conflicts between the first collection of fields and
        # those referenced by each fragment name associated with the second.
        fragment_names_2.each do |fragment_name|
          find_conflicts_between_fields_and_fragment(
            fields,
            fragment_name,
            mutually_exclusive: mutually_exclusive
          )
        end

        # (I) Then collect conflicts between the second collection of fields and
        # those referenced by each fragment name associated with the first.
        fragment_names.each do |fragment_name|
          find_conflicts_between_fields_and_fragment(
            fields2,
            fragment_name,
            mutually_exclusive: mutually_exclusive
          )
        end

        # (J) Also collect conflicts between any fragment names by the first and
        # fragment names by the second. This compares each item in the first set of
        # names to each item in the second set of names.
        fragment_names.each do |frag1|
          fragment_names_2.each do |frag2|
            find_conflicts_between_fragments(
              frag1,
              frag2,
              mutually_exclusive: mutually_exclusive
            )
          end
        end
      end

      def find_conflicts_between(response_keys, response_keys_2, mutually_exclusive:)
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
        selections.map do |node|
          case node
          when GraphQL::Language::Nodes::Field
            {
              node: node,
              parent_type: parent_type,
              defn: context.schema.get_field(parent_type, node.name)
            }
          when GraphQL::Language::Nodes::InlineFragment
            fragment_type = node.type ? context.schema.types[node.type.name] : parent_type

            if fragment_type
              find_fields(node.selections, parent_type: fragment_type)
            else
              # A bad fragment name was provided, let it go and it will be
              # caught by another rule
              nil
            end
          end
        end.compact.flatten
      end

      def response_keys_in_selection(selections, parent_type:)
        fields = find_fields(selections, parent_type: parent_type)
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
