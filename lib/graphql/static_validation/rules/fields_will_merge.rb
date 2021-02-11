 # frozen_string_literal: true

# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FieldsWillMerge
      # Validates that a selection set is valid if all fields (including spreading any
      # fragments) either correspond to distinct response names or can be merged
      # without ambiguity.
      #
      # Original Algorithm: https://github.com/graphql/graphql-js/blob/master/src/validation/rules/OverlappingFieldsCanBeMerged.js
      NO_ARGS = {}.freeze
      Field = Struct.new(:node, :definition, :owner_type, :parents)
      FragmentSpread = Struct.new(:name, :parents)

      def initialize(*)
        super
        @visited_fragments = {}
        @compared_fragments = {}
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

      def conflicts_within_selection_set(node, parent_type)
        return if parent_type.nil?

        fields, fragment_spreads = fields_and_fragments_from_selection(node, owner_type: parent_type, parents: [])

        # (A) Find find all conflicts "within" the fields of this selection set.
        find_conflicts_within(fields)

        fragment_spreads.each_with_index do |fragment_spread, i|
          are_mutually_exclusive = mutually_exclusive?(
            fragment_spread.parents,
            [parent_type]
          )

          # (B) Then find conflicts between these fields and those represented by
          # each spread fragment name found.
          find_conflicts_between_fields_and_fragment(
            fragment_spread,
            fields,
            mutually_exclusive: are_mutually_exclusive,
          )

          # (C) Then compare this fragment with all other fragments found in this
          # selection set to collect conflicts between fragments spread together.
          # This compares each item in the list of fragment names to every other
          # item in that same list (except for itself).
          fragment_spreads[i + 1..-1].each do |fragment_spread2|
            are_mutually_exclusive = mutually_exclusive?(
              fragment_spread.parents,
              fragment_spread2.parents
            )

            find_conflicts_between_fragments(
              fragment_spread,
              fragment_spread2,
              mutually_exclusive: are_mutually_exclusive,
            )
          end
        end
      end

      def find_conflicts_between_fragments(fragment_spread1, fragment_spread2, mutually_exclusive:)
        fragment_name1 = fragment_spread1.name
        fragment_name2 = fragment_spread2.name
        return if fragment_name1 == fragment_name2

        cache_key = compared_fragments_key(
          fragment_name1,
          fragment_name2,
          mutually_exclusive,
        )
        if @compared_fragments.key?(cache_key)
          return
        else
          @compared_fragments[cache_key] = true
        end

        fragment1 = context.fragments[fragment_name1]
        fragment2 = context.fragments[fragment_name2]

        return if fragment1.nil? || fragment2.nil?

        fragment_type1 = context.warden.get_type(fragment1.type.name)
        fragment_type2 = context.warden.get_type(fragment2.type.name)

        return if fragment_type1.nil? || fragment_type2.nil?

        fragment_fields1, fragment_spreads1 = fields_and_fragments_from_selection(
          fragment1,
          owner_type: fragment_type1,
          parents: [*fragment_spread1.parents, fragment_type1]
        )
        fragment_fields2, fragment_spreads2 = fields_and_fragments_from_selection(
          fragment2,
          owner_type: fragment_type1,
          parents: [*fragment_spread2.parents, fragment_type2]
        )

        # (F) First, find all conflicts between these two collections of fields
        # (not including any nested fragments).
        find_conflicts_between(
          fragment_fields1,
          fragment_fields2,
          mutually_exclusive: mutually_exclusive,
        )

        # (G) Then collect conflicts between the first fragment and any nested
        # fragments spread in the second fragment.
        fragment_spreads2.each do |fragment_spread|
          find_conflicts_between_fragments(
            fragment_spread1,
            fragment_spread,
            mutually_exclusive: mutually_exclusive,
          )
        end

        # (G) Then collect conflicts between the first fragment and any nested
        # fragments spread in the second fragment.
        fragment_spreads1.each do |fragment_spread|
          find_conflicts_between_fragments(
            fragment_spread2,
            fragment_spread,
            mutually_exclusive: mutually_exclusive,
          )
        end
      end

      def find_conflicts_between_fields_and_fragment(fragment_spread, fields, mutually_exclusive:)
        fragment_name = fragment_spread.name
        return if @visited_fragments.key?(fragment_name)
        @visited_fragments[fragment_name] = true

        fragment = context.fragments[fragment_name]
        return if fragment.nil?

        fragment_type = context.warden.get_type(fragment.type.name)
        return if fragment_type.nil?

        fragment_fields, fragment_spreads = fields_and_fragments_from_selection(fragment, owner_type: fragment_type, parents: [*fragment_spread.parents, fragment_type])

        # (D) First find any conflicts between the provided collection of fields
        # and the collection of fields represented by the given fragment.
        find_conflicts_between(
          fields,
          fragment_fields,
          mutually_exclusive: mutually_exclusive,
        )

        # (E) Then collect any conflicts between the provided collection of fields
        # and any fragment names found in the given fragment.
        fragment_spreads.each do |fragment_spread|
          find_conflicts_between_fields_and_fragment(
            fragment_spread,
            fields,
            mutually_exclusive: mutually_exclusive,
          )
        end
      end

      def find_conflicts_within(response_keys)
        response_keys.each do |key, fields|
          next if fields.size < 2
          # find conflicts within nodes
          for i in 0..fields.size - 1
            for j in i + 1..fields.size - 1
              find_conflict(key, fields[i], fields[j])
            end
          end
        end
      end

      def find_conflict(response_key, field1, field2, mutually_exclusive: false)
        node1 = field1.node
        node2 = field2.node

        are_mutually_exclusive = mutually_exclusive ||
                                 mutually_exclusive?(field1.parents, field2.parents)

        if !are_mutually_exclusive
          if node1.name != node2.name
            errored_nodes = [node1.name, node2.name].sort.join(" or ")
            msg = "Field '#{response_key}' has a field conflict: #{errored_nodes}?"
            context.errors << GraphQL::StaticValidation::FieldsWillMergeError.new(
              msg,
              nodes: [node1, node2],
              path: [],
              field_name: response_key,
              conflicts: errored_nodes
            )
          end

          if !same_arguments?(node1, node2)
            args = [serialize_field_args(node1), serialize_field_args(node2)]
            conflicts = args.map { |arg| GraphQL::Language.serialize(arg) }.join(" or ")
            msg = "Field '#{response_key}' has an argument conflict: #{conflicts}?"
            context.errors << GraphQL::StaticValidation::FieldsWillMergeError.new(
              msg,
              nodes: [node1, node2],
              path: [],
              field_name: response_key,
              conflicts: conflicts
            )
          end
        end

        find_conflicts_between_sub_selection_sets(
          field1,
          field2,
          mutually_exclusive: are_mutually_exclusive,
        )
      end

      def find_conflicts_between_sub_selection_sets(field1, field2, mutually_exclusive:)
        return if field1.definition.nil? || field2.definition.nil?

        return_type1 = field1.definition.type.unwrap
        return_type2 = field2.definition.type.unwrap
        parents1 = [return_type1]
        parents2 = [return_type2]

        fields, fragment_spreads = fields_and_fragments_from_selection(
          field1.node,
          owner_type: return_type1,
          parents: parents1
        )

        fields2, fragment_spreads2 = fields_and_fragments_from_selection(
          field2.node,
          owner_type: return_type2,
          parents: parents2
        )

        # (H) First, collect all conflicts between these two collections of field.
        find_conflicts_between(fields, fields2, mutually_exclusive: mutually_exclusive)

        # (I) Then collect conflicts between the first collection of fields and
        # those referenced by each fragment name associated with the second.
        fragment_spreads2.each do |fragment_spread|
          find_conflicts_between_fields_and_fragment(
            fragment_spread,
            fields,
            mutually_exclusive: mutually_exclusive,
          )
        end

        # (I) Then collect conflicts between the second collection of fields and
        # those referenced by each fragment name associated with the first.
        fragment_spreads.each do |fragment_spread|
          find_conflicts_between_fields_and_fragment(
            fragment_spread,
            fields2,
            mutually_exclusive: mutually_exclusive,
          )
        end

        # (J) Also collect conflicts between any fragment names by the first and
        # fragment names by the second. This compares each item in the first set of
        # names to each item in the second set of names.
        fragment_spreads.each do |frag1|
          fragment_spreads2.each do |frag2|
            find_conflicts_between_fragments(
              frag1,
              frag2,
              mutually_exclusive: mutually_exclusive
            )
          end
        end
      end

      def find_conflicts_between(response_keys, response_keys2, mutually_exclusive:)
        response_keys.each do |key, fields|
          fields2 = response_keys2[key]
          if fields2
            fields.each do |field|
              fields2.each do |field2|
                find_conflict(
                  key,
                  field,
                  field2,
                  mutually_exclusive: mutually_exclusive,
                )
              end
            end
          end
        end
      end

      NO_SELECTIONS = [{}.freeze, [].freeze].freeze

      def fields_and_fragments_from_selection(node, owner_type:, parents:)
        if node.selections.empty?
          NO_SELECTIONS
        else
          fields, fragment_spreads = find_fields_and_fragments(node.selections, owner_type: owner_type, parents: parents, fields: [], fragment_spreads: [])
          response_keys = fields.group_by { |f| f.node.alias || f.node.name }
          [response_keys, fragment_spreads]
        end
      end

      def find_fields_and_fragments(selections, owner_type:, parents:, fields:, fragment_spreads:)
        selections.each do |node|
          case node
          when GraphQL::Language::Nodes::Field
            definition = context.schema.get_field(owner_type, node.name)
            fields << Field.new(node, definition, owner_type, parents)
          when GraphQL::Language::Nodes::InlineFragment
            fragment_type = node.type ? context.warden.get_type(node.type.name) : owner_type
            find_fields_and_fragments(node.selections, parents: [*parents, fragment_type], owner_type: owner_type, fields: fields, fragment_spreads: fragment_spreads) if fragment_type
          when GraphQL::Language::Nodes::FragmentSpread
            fragment_spreads << FragmentSpread.new(node.name, parents)
          end
        end

        [fields, fragment_spreads]
      end

      def same_arguments?(field1, field2)
        # Check for incompatible / non-identical arguments on this node:
        arguments1 = field1.arguments
        arguments2 = field2.arguments

        return false if arguments1.length != arguments2.length

        arguments1.all? do |argument1|
          argument2 = arguments2.find { |argument| argument.name == argument1.name }
          return false if argument2.nil?

          serialize_arg(argument1.value) == serialize_arg(argument2.value)
        end
      end

      def serialize_arg(arg_value)
        case arg_value
        when GraphQL::Language::Nodes::AbstractNode
          arg_value.to_query_string
        when Array
          "[#{arg_value.map { |a| serialize_arg(a) }.join(", ")}]"
        else
          GraphQL::Language.serialize(arg_value)
        end
      end

      def serialize_field_args(field)
        serialized_args = {}
        field.arguments.each do |argument|
          serialized_args[argument.name] = serialize_arg(argument.value)
        end
        serialized_args
      end

      def compared_fragments_key(frag1, frag2, exclusive)
        # Cache key to not compare two fragments more than once.
        # The key includes both fragment names sorted (this way we
        # avoid computing "A vs B" and "B vs A"). It also includes
        # "exclusive" since the result may change depending on the parent_type
        "#{[frag1, frag2].sort.join('-')}-#{exclusive}"
      end

      # Given two list of parents, find out if they are mutually exclusive
      # In this context, `parents` represends the "self scope" of the field,
      # what types may be found at this point in the query.
      def mutually_exclusive?(parents1, parents2)
        parents1.each do |type1|
          parents2.each do |type2|
            # If the types we're comparing are both different object types,
            # they have to be mutually exclusive.
            if type1 != type2 && type1.kind.object? && type2.kind.object?
              return true
            end
          end
        end

        false
      end
    end
  end
end
