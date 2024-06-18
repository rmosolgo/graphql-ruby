# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      class GatherSelections
        def initialize(query)
          @query = query
          default_selections_on_node = Hash.new { |h, k| h[k] = [nil, nil, {}] }.compare_by_identity
          @selections_for_result = Hash.new { |h, graphql_result_hash|
            selections_on_node = default_selections_on_node.dup
            selections = graphql_result_hash.graphql_selections
            build_cached_selections(selections, nil, selections_on_node)
            h[graphql_result_hash] = selections_on_node
          }.compare_by_identity
          @runtime_directive_names = []
          noop_resolve_owner = GraphQL::Schema::Directive.singleton_class
          @schema_directives = query.schema.directives
          @schema_directives.each do |name, dir_defn|
            if dir_defn.method(:resolve).owner != noop_resolve_owner
              @runtime_directive_names << name
            end
          end
        end

        def each_gathered_selections(graphql_result_hash)
          selections_on_node = @selections_for_result[graphql_result_hash]
          object = graphql_result_hash.graphql_application_value
          type = graphql_result_hash.graphql_result_type
          single_selection = nil
          has_merged_selections = false
          selections_on_node.each do |node, (type_condition, directives, selections)|
            if type_condition
              type_defn = @query.get_type(type_condition.name)
              pt = @query.warden.possible_types(type_defn)
              if !pt.include?(type)
                # These selections failed type condition
                next
              end
            end

            if directives&.any?
              passes_dirs = directives.all? do |dir_node|
                dir_defn = @schema_directives.fetch(dir_node.name)
                args = if dir_defn.arguments_statically_coercible?
                  @query.arguments_for(dir_node, dir_defn)
                else
                  # The arguments must be prepared in the context of the given object
                  @query.arguments_for(dir_node, dir_defn, parent_object: object)
                end

                dir_defn.include?(object, args, @query.context)
              end
              if !passes_dirs
                # Skipped by directives
                next
              end
            end

            if single_selection.nil?
              single_selection = selections
            else
              if has_merged_selections == false
                single_selection = single_selection.dup
                has_merged_selections = true
              end

              single_selection.merge!(selections)
            end
          end

          yield(single_selection)
        end

        private

        def build_cached_selections(ast_selections, gathered_selections, selections_by_node)
          if gathered_selections.nil?
            _type_cond, _dirs, gathered_selections = selections_by_node[nil]
          end

          ast_selections.each do |node|
            case node
            when GraphQL::Language::Nodes::Field
              key = node.alias || node.name
              if node.directives.any?
                next_sels = selections_by_node[node]
                next_sels[1] = node.directives
                next_sels[2][key] = node
              else
                gathered_selections[key] = node
              end
            when GraphQL::Language::Nodes::InlineFragment
              if node.directives.any? || node.type
                next_sels_config = selections_by_node[node]
                next_sels_config[0] = node.type
                next_sels_config[1] = node.directives
                build_cached_selections(node.selections, next_sels_config[2], selections_by_node)
              else
                build_cached_selections(node.selections, gathered_selections, selections_by_node)
              end
            when GraphQL::Language::Nodes::FragmentSpread
              fragment_def = @query.fragments[node.name]
              next_sels_config = selections_by_node[node]
              next_sels_config[0] = fragment_def.type
              next_sels_config[1] = node.directives # Use directives from the spread, not the def
              build_cached_selections(fragment_def.selections, next_sels_config[2], selections_by_node)
            end
          end
        end
      end
    end
  end
end
