 # frozen_string_literal: true

# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FieldsWillMerge
      # Validates that a selection set is valid if all fields (including spreading any
      # fragments) either correspond to distinct response names or can be merged
      # without ambiguity.
      #
      # Optimized algorithm based on:
      # https://tech.new-work.se/graphql-overlapping-fields-can-be-merged-fast-ea6e92e0a01
      #
      # Instead of comparing fields, fields-vs-fragments, and fragments-vs-fragments
      # separately (which leads to exponential recursion through nested fragments),
      # we flatten all fragment spreads into a single field map and compare within it.
      NO_ARGS = GraphQL::EmptyObjects::EMPTY_HASH

      class Field
        attr_reader :node, :definition, :owner_type, :parents

        def initialize(node, definition, owner_type, parents)
          @node = node
          @definition = definition
          @owner_type = owner_type
          @parents = parents
        end

        def return_type
          @return_type ||= @definition&.type
        end

        def unwrapped_return_type
          @unwrapped_return_type ||= return_type&.unwrap
        end
      end

      def initialize(*)
        super
        @conflict_count = 0
        @max_errors = context.max_errors
        @fragments = context.fragments
        # Track which sub-selection node pairs have been compared to prevent
        # infinite recursion with cyclic fragments
        @compared_sub_selections = {}.compare_by_identity
        # Cache mutually_exclusive? results for type pairs
        @mutually_exclusive_cache = {}.compare_by_identity
        # Cache collect_fields results for sub-selection comparison
        # Keyed by (node, return_type) since parents is always [return_type]
        @sub_fields_cache = {}.compare_by_identity
      end

      def on_operation_definition(node, _parent)
        @conflicts = nil
        conflicts_within_selection_set(node, type_definition)
        @conflicts&.each_value { |error_type| error_type.each_value { |error| add_error(error) } }
        super
      end

      def on_field(node, _parent)
        if !node.selections.empty? && selections_may_conflict?(node.selections)
          @conflicts = nil
          conflicts_within_selection_set(node, type_definition)
          @conflicts&.each_value { |error_type| error_type.each_value { |error| add_error(error) } }
        end
        super
      end

      private

      # Quick check: can the direct children of this selection set possibly conflict?
      # If all direct selections are Fields with unique names and no aliases,
      # and there are no fragments, then no response key can have >1 field,
      # so there are no merge conflicts to check at this level.
      def selections_may_conflict?(selections)
        i = 0
        len = selections.size
        while i < len
          sel = selections[i]
          # Fragment spread or inline fragment — needs full check
          return true unless sel.is_a?(GraphQL::Language::Nodes::Field)
          # Aliased field — could create duplicate response key
          return true if sel.alias
          i += 1
        end
        # All are unaliased fields — check for duplicate names
        # For small sets, O(n²) is cheaper than hash allocation
        if len <= 8
          i = 0
          while i < len
            j = i + 1
            name_i = selections[i].name
            while j < len
              return true if selections[j].name == name_i
              j += 1
            end
            i += 1
          end
          false
        else
          true # Assume potential conflicts for larger sets
        end
      end

      def conflicts
        @conflicts ||= Hash.new do |h, error_type|
          h[error_type] = Hash.new do |h2, field_name|
            h2[field_name] = GraphQL::StaticValidation::FieldsWillMergeError.new(kind: error_type, field_name: field_name)
          end
        end
      end

      # Core algorithm: collect ALL fields (expanding fragments inline) into a flat
      # map keyed by response key, then compare within each group.
      def conflicts_within_selection_set(node, parent_type)
        return if parent_type.nil?
        return if node.selections.empty?

        # Collect all fields from this selection set, expanding fragments transitively
        response_keys = collect_fields(node.selections, owner_type: parent_type, parents: [])

        # Find conflicts within each response key group
        find_conflicts_within(response_keys)
      end

      # Collect all fields from selections, expanding fragment spreads inline.
      # Returns a Hash of { response_key => [Field, ...] }
      def collect_fields(selections, owner_type:, parents:)
        response_keys = {}
        visited = {}
        collect_fields_inner(selections, owner_type: owner_type, parents: parents, response_keys: response_keys, visited_fragments: visited)
        response_keys
      end

      def collect_fields_inner(selections, owner_type:, parents:, response_keys:, visited_fragments:)
        # Collect direct fields and inline fragments first, then expand named fragments.
        # This maintains field ordering compatible with the original algorithm where
        # direct fields are compared before fragment fields.
        deferred_spreads = nil
        sel_idx = 0
        sel_len = selections.size
        while sel_idx < sel_len
          sel = selections[sel_idx]
          case sel
          when GraphQL::Language::Nodes::Field
            definition = @types.field(owner_type, sel.name)
            key = sel.alias || sel.name
            field = Field.new(sel, definition, owner_type, parents)
            if (arr = response_keys[key])
              arr << field
            else
              response_keys[key] = [field]
            end
          when GraphQL::Language::Nodes::InlineFragment
            frag_type = sel.type ? @types.type(sel.type.name) : owner_type
            if frag_type
              new_parents = parents.dup
              new_parents << frag_type
              collect_fields_inner(sel.selections, owner_type: frag_type, parents: new_parents, response_keys: response_keys, visited_fragments: visited_fragments)
            end
          when GraphQL::Language::Nodes::FragmentSpread
            (deferred_spreads ||= []) << sel
          end
          sel_idx += 1
        end

        if deferred_spreads
          sel_idx = 0
          sel_len = deferred_spreads.size
          while sel_idx < sel_len
            sel = deferred_spreads[sel_idx]
            sel_idx += 1
            next if visited_fragments.key?(sel.name)
            visited_fragments[sel.name] = true
            frag = @fragments[sel.name]
            next unless frag
            frag_type = @types.type(frag.type.name)
            next unless frag_type
            new_parents = parents.dup
            new_parents << frag_type
            collect_fields_inner(frag.selections, owner_type: frag_type, parents: new_parents, response_keys: response_keys, visited_fragments: visited_fragments)
          end
        end
      end

      def find_conflicts_within(response_keys)
        response_keys.each do |key, fields|
          next if fields.size < 2

          # Optimization: group fields by a signature (name + definition + arguments).
          # Fields with the same signature can only conflict on sub-selections,
          # so we only need to compare one pair within each group.
          # Fields with different signatures need cross-group comparison.
          if fields.size > 4
            # Fast path: check if all fields share the same signature
            # by comparing each to the first field
            f0 = fields[0]
            all_same = true
            i = 1
            while i < fields.size
              unless fields_same_signature?(f0, fields[i])
                all_same = false
                break
              end
              i += 1
            end

            if all_same
              # All fields are identical in signature — just compare first two
              # (they share definition, name, args — only sub-selections could differ)
              if f0.node.selections.size > 0 || fields[1].node.selections.size > 0
                find_conflict(key, f0, fields[1])
              end
              # If no selections on either, there's nothing that can conflict
            else
              groups = fields.group_by { |f| field_signature(f) }
              unique_groups = groups.values

              # Compare representatives across different groups
              gi = 0
              while gi < unique_groups.size
                gj = gi + 1
                while gj < unique_groups.size
                  # Compare one representative from each group
                  find_conflict(key, unique_groups[gi][0], unique_groups[gj][0])
                  gj += 1
                end
                # Within same group, only check first pair for sub-selection conflicts
                group = unique_groups[gi]
                if group.size >= 2 && (group[0].node.selections.size > 0 || group[1].node.selections.size > 0)
                  find_conflict(key, group[0], group[1])
                end
                gi += 1
              end
            end
          else
            # Small number of fields — original O(n²) is fine
            i = 0
            while i < fields.size
              j = i + 1
              while j < fields.size
                find_conflict(key, fields[i], fields[j])
                j += 1
              end
              i += 1
            end
          end
        end
      end

      def fields_same_signature?(f1, f2)
        n1 = f1.node
        n2 = f2.node
        f1.definition.equal?(f2.definition) &&
          n1.name == n2.name &&
          same_arguments?(n1, n2)
      end

      def field_signature(field)
        node = field.node
        defn = field.definition
        args = node.arguments
        if args.empty?
          [node.name, defn.object_id]
        else
          [node.name, defn.object_id, args.map { |a| [a.name, serialize_arg(a.value)] }]
        end
      end

      def find_conflict(response_key, field1, field2, mutually_exclusive: false)
        return if @conflict_count >= @max_errors
        return if field1.definition.nil? || field2.definition.nil?

        node1 = field1.node
        node2 = field2.node

        are_mutually_exclusive = mutually_exclusive ||
                                 mutually_exclusive?(field1.parents, field2.parents)

        if !are_mutually_exclusive
          if node1.name != node2.name
            conflict = conflicts[:field][response_key]

            conflict.add_conflict(node1, node1.name)
            conflict.add_conflict(node2, node2.name)

            @conflict_count += 1
          end

          if !same_arguments?(node1, node2)
            conflict = conflicts[:argument][response_key]

            conflict.add_conflict(node1, GraphQL::Language.serialize(serialize_field_args(node1)))
            conflict.add_conflict(node2, GraphQL::Language.serialize(serialize_field_args(node2)))

            @conflict_count += 1
          end
        end

        if !conflicts[:field].key?(response_key) &&
            !field1.definition.equal?(field2.definition) &&
            (t1 = field1.return_type) &&
            (t2 = field2.return_type) &&
            return_types_conflict?(t1, t2)

          return_error = nil
          message_override = nil
          case @schema.allow_legacy_invalid_return_type_conflicts
          when false
            return_error = true
          when true
            legacy_handling = @schema.legacy_invalid_return_type_conflicts(@context.query, t1, t2, node1, node2)
            case legacy_handling
            when nil
              return_error = false
            when :return_validation_error
              return_error = true
            when String
              return_error = true
              message_override = legacy_handling
            else
              raise GraphQL::Error, "#{@schema}.legacy_invalid_scalar_conflicts returned unexpected value: #{legacy_handling.inspect}. Expected `nil`, String, or `:return_validation_error`."
            end
          else
            return_error = false
            @context.query.logger.warn <<~WARN
              GraphQL-Ruby encountered mismatched types in this query: `#{t1.to_type_signature}` (at #{node1.line}:#{node1.col}) vs. `#{t2.to_type_signature}` (at #{node2.line}:#{node2.col}).
              This will return an error in future GraphQL-Ruby versions, as per the GraphQL specification
              Learn about migrating here: https://graphql-ruby.org/api-doc/#{GraphQL::VERSION}/GraphQL/Schema.html#allow_legacy_invalid_return_type_conflicts-class_method
            WARN
          end

          if return_error
            conflict = conflicts[:return_type][response_key]
            if message_override
              conflict.message = message_override
            end
            conflict.add_conflict(node1, "`#{t1.to_type_signature}`")
            conflict.add_conflict(node2, "`#{t2.to_type_signature}`")
            @conflict_count += 1
          end
        end

        find_conflicts_between_sub_selection_sets(
          field1,
          field2,
          mutually_exclusive: are_mutually_exclusive,
        )
      end

      def return_types_conflict?(type1, type2)
        if type1.list?
          if type2.list?
            return_types_conflict?(type1.of_type, type2.of_type)
          else
            true
          end
        elsif type2.list?
          true
        elsif type1.non_null?
          if type2.non_null?
            return_types_conflict?(type1.of_type, type2.of_type)
          else
            true
          end
        elsif type2.non_null?
          true
        elsif type1.kind.leaf? && type2.kind.leaf?
          type1 != type2
        else
          # One or more of these are composite types,
          # their selections will be validated later on.
          false
        end
      end

      # When two fields with the same response key both have sub-selections,
      # we need to check those sub-selections against each other.
      def find_conflicts_between_sub_selection_sets(field1, field2, mutually_exclusive:)
        return if field1.definition.nil? ||
          field2.definition.nil? ||
          (field1.node.selections.empty? && field2.node.selections.empty?)

        node1 = field1.node
        node2 = field2.node

        # Prevent infinite recursion from cyclic fragments by tracking
        # which node pairs we've already processed
        if node1.equal?(node2)
          # Same node — conflicts within are handled by on_field visitor
          return
        end

        inner = @compared_sub_selections[node1]
        if inner
          return if inner.key?(node2)
          inner[node2] = true
        else
          inner = {}.compare_by_identity
          inner[node2] = true
          @compared_sub_selections[node1] = inner
        end

        return_type1 = field1.unwrapped_return_type
        return_type2 = field2.unwrapped_return_type

        # Collect all fields (including from fragments) for each sub-selection set
        # Cache by (node, return_type) since this can be called repeatedly for
        # the same sub-selection set from different comparison contexts
        response_keys1 = cached_sub_fields(node1, return_type1)
        response_keys2 = cached_sub_fields(node2, return_type2)

        # Compare fields between the two sets
        find_conflicts_between(response_keys1, response_keys2, mutually_exclusive: mutually_exclusive)
      end

      def cached_sub_fields(node, return_type)
        inner = @sub_fields_cache[node]
        if inner && inner.key?(return_type)
          inner[return_type]
        else
          result = collect_fields(node.selections, owner_type: return_type, parents: [return_type])
          inner ||= {}.compare_by_identity
          inner[return_type] = result
          @sub_fields_cache[node] = inner
          result
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

      # Given two list of parents, find out if they are mutually exclusive
      # In this context, `parents` represents the "self scope" of the field,
      # what types may be found at this point in the query.
      def mutually_exclusive?(parents1, parents2)
        if parents1.empty? || parents2.empty?
          false
        elsif parents1.length == parents2.length
          i = 0
          len = parents1.length
          while i < len
            type1 = parents1[i - 1]
            type2 = parents2[i - 1]
            unless type1.equal?(type2)
              # Check cache for this type pair
              inner = @mutually_exclusive_cache[type1]
              if inner
                cached = inner[type2]
                if cached.nil?
                  cached = types_mutually_exclusive?(type1, type2)
                  inner[type2] = cached
                end
              else
                cached = types_mutually_exclusive?(type1, type2)
                inner = {}.compare_by_identity
                inner[type2] = cached
                @mutually_exclusive_cache[type1] = inner
              end
              return true if cached
            end
            i += 1
          end
          false
        else
          true
        end
      end

      def types_mutually_exclusive?(type1, type2)
        possible_right_types = @types.possible_types(type1)
        possible_left_types = @types.possible_types(type2)
        !possible_right_types.intersect?(possible_left_types)
      end
    end
  end
end
