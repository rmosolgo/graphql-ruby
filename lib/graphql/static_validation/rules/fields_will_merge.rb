 # frozen_string_literal: true
# typed: false

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
      EXCLUSIVE_COMPARISON = 1
      NONEXCLUSIVE_COMPARISON = 2

      class Field
        attr_reader :node, :definition, :owner_type, :parents

        # `parents` is only for the legacy check, see `legacy_mutually_exclusive?`
        def initialize(node, definition, owner_type, parents)
          @node = node
          @definition = definition
          @owner_type = owner_type
          @parents = parents
        end

        # The types which decide if this field is mutually exclusive with other fields
        def scope
          @parents || @owner_type
        end

        def return_type
          @return_type ||= @definition&.type
        end

        def unwrapped_return_type
          @unwrapped_return_type ||= return_type&.unwrap
        end

        def comparison_key
          @comparison_key ||= [@node, scope]
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
        @compared_field_groups = {}
        @field_group_signatures = {}.compare_by_identity
        @field_selection_signatures = {}.compare_by_identity
        # Cache collect_fields results for sub-selection comparison
        @sub_fields_cache = {}.compare_by_identity

        @allow_legacy_invalid_field_conflicts = @schema.allow_legacy_invalid_field_conflicts
        # Unless legacy conflicts are rejected, use the legacy check, which is the same as previous versions.
        # It uses `legacy_mutually_exclusive?` and the caches above. The spec check uses `@spec_caches`.
        @legacy_exclusivity = @allow_legacy_invalid_field_conflicts != false
        @spec_caches = nil
        @mutually_exclusive_cache = nil
        # True when the spec check can find conflicts which the legacy check doesn't find
        @spec_check_needed = false
        # During the legacy check, true when the spec rule treats the parent fields as mutually exclusive
        @spec_inherited_exclusive = false
        # The pairs of nodes which have a conflict in the legacy check
        @legacy_conflict_nodes = nil
        # When this is true, record conflicts in `@spec_conflicts` instead of adding errors
        @find_spec_conflicts = false
        @spec_conflicts = nil
      end

      def on_operation_definition(node, _parent)
        check_selection_set(node, type_definition)
        super
      end

      def on_field(node, _parent)
        if !node.selections.empty? && selections_may_conflict?(node.selections)
          check_selection_set(node, type_definition)
        end
        super
      end

      private

      #: (untyped node, untyped parent_type) -> void
      def check_selection_set(node, parent_type)
        @conflicts = nil
        @spec_check_needed = false
        conflicts_within_selection_set(node, parent_type)

        if @spec_check_needed
          # Find the conflicts with the spec check, without errors or warnings. The new ones are legacy conflicts.
          legacy_conflicts = @conflicts
          conflict_count = @conflict_count
          @conflicts = nil
          with_spec_check { conflicts_within_selection_set(node, parent_type) }
          @conflicts = legacy_conflicts
          @conflict_count = conflict_count
          legacy_conflict_nodes = (@legacy_conflict_nodes ||= {}.compare_by_identity)
          @spec_conflicts&.each do |(response_key, node1, node2, different_names, different_arguments, type1, type2)|
            next if legacy_conflict_nodes[node1]&.key?(node2)
            add_legacy_invalid_conflict(response_key, node1, node2, different_names, different_arguments, type1, type2)
            add_legacy_conflict_nodes(node1, node2)
          end
          @spec_conflicts = nil
        end

        @conflicts&.each_value { |error_type| error_type.each_value { |error| add_error(error) } }
      end

      # Use the spec rule for mutually exclusive fields, with its own caches, and record conflicts in `@spec_conflicts`
      #: () { () -> void } -> void
      def with_spec_check(&block)
        legacy_caches = [@compared_sub_selections, @compared_field_groups, @field_group_signatures, @sub_fields_cache]
        @compared_sub_selections, @compared_field_groups, @field_group_signatures, @sub_fields_cache =
          (@spec_caches ||= [{}.compare_by_identity, {}, {}.compare_by_identity, {}.compare_by_identity])
        @legacy_exclusivity = false
        @find_spec_conflicts = true
        yield
      ensure
        @legacy_exclusivity = true
        @find_spec_conflicts = false
        @compared_sub_selections, @compared_field_groups, @field_group_signatures, @sub_fields_cache = legacy_caches
      end

      #: (untyped response_key, GraphQL::Language::Nodes::Field node1, GraphQL::Language::Nodes::Field node2, bool different_names, bool different_arguments, untyped type1, untyped type2) -> void
      def add_legacy_invalid_conflict(response_key, node1, node2, different_names, different_arguments, type1, type2)
        message_override = nil
        if @allow_legacy_invalid_field_conflicts == true
          legacy_handling = @schema.legacy_invalid_field_conflicts(@context.query, node1, node2)
          case legacy_handling
          when nil
            return
          when :return_validation_error
            # Add the error below
          when String
            message_override = legacy_handling
          else
            raise GraphQL::Error, "#{@schema}.legacy_invalid_field_conflicts returned unexpected value: #{legacy_handling.inspect}. Expected `nil`, String, or `:return_validation_error`."
          end
        else
          @context.query.logger.warn <<~WARN
            GraphQL-Ruby encountered fields which can't be merged in this query: `#{node1.name}` (at #{node1.line}:#{node1.col}) vs. `#{node2.name}` (at #{node2.line}:#{node2.col}).
            This will return an error in future GraphQL-Ruby versions, as per the GraphQL specification
            Learn about migrating here: https://graphql-ruby.org/api-doc/#{GraphQL::VERSION}/GraphQL/Schema.html#allow_legacy_invalid_field_conflicts-class_method
          WARN
          return
        end

        if type1
          conflict = conflicts[:return_type][response_key]
          conflict.message = message_override if message_override
          conflict.add_conflict(node1, "`#{type1.to_type_signature}`")
          conflict.add_conflict(node2, "`#{type2.to_type_signature}`")
          @conflict_count += 1
        else
          add_field_conflict(response_key, node1, node2, different_names, different_arguments, message_override)
        end
      end

      #: (GraphQL::Language::Nodes::Field node1, GraphQL::Language::Nodes::Field node2) -> void
      def add_legacy_conflict_nodes(node1, node2)
        legacy_conflict_nodes = (@legacy_conflict_nodes ||= {}.compare_by_identity)
        (legacy_conflict_nodes[node1] ||= {}.compare_by_identity)[node2] = true
        (legacy_conflict_nodes[node2] ||= {}.compare_by_identity)[node1] = true
      end

      #: (untyped response_key, GraphQL::Language::Nodes::Field node1, GraphQL::Language::Nodes::Field node2, bool different_names, bool different_arguments, String? message_override) -> void
      def add_field_conflict(response_key, node1, node2, different_names, different_arguments, message_override)
        if different_names
          conflict = conflicts[:field][response_key]
          conflict.message = message_override if message_override
          conflict.add_conflict(node1, node1.name)
          conflict.add_conflict(node2, node2.name)
          @conflict_count += 1
        end

        if different_arguments
          conflict = conflicts[:argument][response_key]
          conflict.message = message_override if message_override
          conflict.add_conflict(node1, GraphQL::Language.serialize(serialize_field_args(node1)))
          conflict.add_conflict(node2, GraphQL::Language.serialize(serialize_field_args(node2)))
          @conflict_count += 1
        end
      end

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
        response_keys = collect_fields(node.selections, owner_type: parent_type, parents: @legacy_exclusivity ? [] : nil)

        # Find conflicts within each response key group
        find_conflicts_within(response_keys)
      end

      # Collect all fields from selections, expanding fragment spreads inline.
      # Returns a Hash of { response_key => Field | [Field, ...] }
      def collect_fields(selections, owner_type:, parents:)
        response_keys = {}
        collect_fields_inner(selections, owner_type: owner_type, parents: parents, response_keys: response_keys, visited_fragments: nil)
        response_keys
      end

      def collect_fields_inner(selections, owner_type:, parents:, response_keys:, visited_fragments:)
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
            existing = response_keys[key]

            if existing.nil?
              response_keys[key] = field
            elsif existing.is_a?(Field)
              response_keys[key] = [existing, field]
            else
              existing << field
            end
          when GraphQL::Language::Nodes::InlineFragment
            frag_type = sel.type ? @types.type(sel.type.name) : owner_type

            if frag_type
              new_parents = parents && (parents.dup << frag_type)
              collect_fields_inner(sel.selections, owner_type: frag_type, parents: new_parents, response_keys: response_keys, visited_fragments: visited_fragments)
            end
          when GraphQL::Language::Nodes::FragmentSpread
            (deferred_spreads ||= []) << sel
          end

          sel_idx += 1
        end

        if deferred_spreads
          visited_fragments ||= {}
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

            new_parents = parents && (parents.dup << frag_type)
            collect_fields_inner(frag.selections, owner_type: frag_type, parents: new_parents, response_keys: response_keys, visited_fragments: visited_fragments)
          end
        end
      end

      def find_conflicts_within(response_keys)
        response_keys.each do |key, fields|
          next unless fields.is_a?(Array)

          # Optimization: compare only one of the fields which have the same signature
          # (name + definition + arguments), parent type and sub-selections.
          if fields.size > 4 && @legacy_exclusivity
            legacy_find_conflicts_within(key, fields)
          elsif fields.size > 4
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
              # These fields can only conflict on sub-selections.
              find_conflicts_between_selection_groups(key, fields)
            else
              representatives = {}
              fields.each do |field|
                representatives[[field_signature(field), field.scope, field_selection_signature(field)]] ||= field
              end
              representatives = representatives.values

              i = 0
              while i < representatives.size
                j = i + 1
                while j < representatives.size
                  find_conflict(key, representatives[i], representatives[j])
                  j += 1
                end
                i += 1
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

      # Previous versions compared only the first field of each group of fields with the same signature,
      # and one field for each sub-selection in a group. For the spec check, that's the same as comparing each field,
      # unless the fields in a group have different parent types or sub-selections. Then the spec check can find more conflicts.
      #: (untyped response_key, Array[Field] fields) -> void
      def legacy_find_conflicts_within(response_key, fields)
        f0 = fields[0]
        n0 = f0.node
        if fields.all? { |f| f.definition.equal?(f0.definition) && f.node.name == n0.name && same_arguments?(f.node, n0) }
          find_conflicts_between_selection_groups(response_key, fields)
          if !@spec_check_needed && !fields.all? { |f| f.node.selections.empty? || f.owner_type.equal?(f0.owner_type) }
            @spec_check_needed = true
          end
        else
          groups = fields.group_by { |f| field_signature(f) }.values
          gi = 0
          while gi < groups.size
            gj = gi + 1
            while gj < groups.size
              find_conflict(response_key, groups[gi][0], groups[gj][0])
              gj += 1
            end
            group = groups[gi]
            if group.size >= 2
              find_conflicts_between_selection_groups(response_key, group)
              if !@spec_check_needed
                g0 = group[0]
                g0_selections = field_selection_signature(g0)
                @spec_check_needed = !group.all? { |f| f.owner_type.equal?(g0.owner_type) && field_selection_signature(f) == g0_selections }
              end
            end
            gi += 1
          end
        end
      end

      def find_conflicts_between_selection_groups(response_key, fields)
        fields_by_selection = {}
        fields.each do |field|
          fields_by_selection[field_selection_signature(field)] ||= field
        end

        representatives = fields_by_selection.values
        i = 0
        while i < representatives.size
          j = i + 1
          while j < representatives.size
            find_conflict(response_key, representatives[i], representatives[j])
            j += 1
          end
          i += 1
        end
      end

      def field_selection_signature(field)
        node = field.node
        @field_selection_signatures[node] ||= node.selections.map(&:to_query_string)
      end

      def fields_same_signature?(f1, f2)
        n1 = f1.node
        n2 = f2.node

        f1.definition.equal?(f2.definition) &&
          f1.scope == f2.scope &&
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

        are_mutually_exclusive = mutually_exclusive || mutually_exclusive?(field1, field2)

        if !are_mutually_exclusive
          different_names = node1.name != node2.name
          different_arguments = !same_arguments?(node1, node2)
          if different_names || different_arguments
            if @find_spec_conflicts
              (@spec_conflicts ||= []) << [response_key, node1, node2, different_names, different_arguments, nil, nil]
              @conflict_count += 1
            else
              add_field_conflict(response_key, node1, node2, different_names, different_arguments, nil)
              add_legacy_conflict_nodes(node1, node2) if @legacy_exclusivity
            end

            # Like graphql-js, stop here: the document is already invalid, and comparing sub-selections can be slow.
            return
          end
        elsif @legacy_exclusivity
          # If the spec rule doesn't treat these fields as mutually exclusive, it can find a conflict
          spec_exclusive = @spec_inherited_exclusive || spec_mutually_exclusive?(field1, field2)
          if !spec_exclusive && !@spec_check_needed && (node1.name != node2.name || !same_arguments?(node1, node2))
            @spec_check_needed = true
          end
        end

        if !conflicts[:field].key?(response_key) &&
            !field1.definition.equal?(field2.definition) &&
            (t1 = field1.return_type) &&
            (t2 = field2.return_type) &&
            return_types_conflict?(t1, t2)
          if @find_spec_conflicts
            (@spec_conflicts ||= []) << [response_key, node1, node2, false, false, t1, t2]
          else
            add_return_type_conflict(response_key, t1, t2, node1, node2)
            add_legacy_conflict_nodes(node1, node2) if @legacy_exclusivity
          end
        end

        if spec_exclusive && !@spec_inherited_exclusive
          @spec_inherited_exclusive = true
          find_conflicts_between_sub_selection_sets(field1, field2, mutually_exclusive: are_mutually_exclusive)
          @spec_inherited_exclusive = false
        else
          find_conflicts_between_sub_selection_sets(field1, field2, mutually_exclusive: are_mutually_exclusive)
        end
      end

      #: (untyped response_key, untyped t1, untyped t2, GraphQL::Language::Nodes::Field node1, GraphQL::Language::Nodes::Field node2) -> void
      def add_return_type_conflict(response_key, t1, t2, node1, node2)
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

      # SameResponseShape in the spec. Compare one wrapper at a time: `list?` is also true for a non-null list.
      #: (untyped type1, untyped type2) -> bool
      def return_types_conflict?(type1, type2)
        kind1 = type1.kind
        kind2 = type2.kind
        if kind1.non_null? || kind2.non_null?
          !(kind1.non_null? && kind2.non_null?) || return_types_conflict?(type1.of_type, type2.of_type)
        elsif kind1.list? || kind2.list?
          !(kind1.list? && kind2.list?) || return_types_conflict?(type1.of_type, type2.of_type)
        elsif kind1.leaf? || kind2.leaf?
          type1 != type2
        else
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

        # Prevent infinite recursion from cyclic fragments
        return if node1.equal?(node2)

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

        response_keys1 = cached_sub_fields(node1, return_type1)
        response_keys2 = cached_sub_fields(node2, return_type2)

        find_conflicts_between(response_keys1, response_keys2, mutually_exclusive: mutually_exclusive)
      end

      def cached_sub_fields(node, return_type)
        inner = @sub_fields_cache[node]

        if inner && inner.key?(return_type)
          inner[return_type]
        else
          result = collect_fields(node.selections, owner_type: return_type, parents: @legacy_exclusivity ? [return_type] : nil)
          inner ||= {}.compare_by_identity
          inner[return_type] = result
          @sub_fields_cache[node] = inner
          result
        end
      end

      def find_conflicts_between(response_keys, response_keys2, mutually_exclusive:)
        response_keys.each do |key, fields|
          fields2 = response_keys2[key]
          next unless fields2
          next if field_groups_already_compared?(fields, fields2, mutually_exclusive)

          fields_arr = fields.is_a?(Field) ? [fields] : fields
          fields2_arr = fields2.is_a?(Field) ? [fields2] : fields2

          fields_arr.each do |field|
            fields2_arr.each do |field2|
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

      def field_groups_already_compared?(fields, fields2, mutually_exclusive)
        signature1 = field_group_signature(fields)
        signature2 = field_group_signature(fields2)
        previous_comparisons = @compared_field_groups[signature1]
        comparison_state = previous_comparisons && previous_comparisons[signature2]

        if mutually_exclusive
          return true if comparison_state
          new_state = EXCLUSIVE_COMPARISON
        else
          return true if comparison_state == NONEXCLUSIVE_COMPARISON
          new_state = NONEXCLUSIVE_COMPARISON
        end

        previous_comparisons ||= (@compared_field_groups[signature1] = {})
        previous_comparisons[signature2] = new_state

        reverse_comparisons = @compared_field_groups[signature2] ||= {}
        reverse_comparisons[signature1] = new_state
        false
      end

      def field_group_signature(fields)
        if fields.is_a?(Field)
          fields.comparison_key
        else
          @field_group_signatures[fields] ||= fields.map(&:comparison_key)
        end
      end

      def same_arguments?(field1, field2)
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

      #: (Field field1, Field field2) -> bool
      def mutually_exclusive?(field1, field2)
        @legacy_exclusivity ? legacy_mutually_exclusive?(field1.parents, field2.parents) : spec_mutually_exclusive?(field1, field2)
      end

      # As in the spec (FieldsInSetCanMerge), only fields on different object types are mutually exclusive,
      # even if no runtime object can be selected by both of them.
      #: (Field field1, Field field2) -> bool
      def spec_mutually_exclusive?(field1, field2)
        owner_type1 = field1.owner_type
        owner_type2 = field2.owner_type
        !owner_type1.equal?(owner_type2) && owner_type1.kind.object? && owner_type2.kind.object?
      end

      # Previous versions compared the lists of type conditions above each field, position by position,
      # and treated lists with different lengths as mutually exclusive.
      #: (Array[untyped] parents1, Array[untyped] parents2) -> bool
      def legacy_mutually_exclusive?(parents1, parents2)
        if parents1.empty? || parents2.empty?
          false
        elsif parents1.length == parents2.length
          cache = (@mutually_exclusive_cache ||= {}.compare_by_identity)
          i = 0
          len = parents1.length
          while i < len
            type1 = parents1[i - 1]
            type2 = parents2[i - 1]
            unless type1.equal?(type2)
              inner = (cache[type1] ||= {}.compare_by_identity)
              exclusive = inner[type2]
              if exclusive.nil?
                exclusive = inner[type2] = (@types.possible_types(type1) & @types.possible_types(type2)).empty?
              end
              return true if exclusive
            end
            i += 1
          end
          false
        else
          true
        end
      end
    end
  end
end
