# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      class GatherSelections
        def initialize(query)
          @query = query
          @selections_by_node = Hash.new { |h, ast_node|
          # TODO dedicated class for storage
            h[ast_node] = [nil, nil, {}, []]
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
          object = graphql_result_hash.graphql_application_value
          type = graphql_result_hash.graphql_result_type
          selections = graphql_result_hash.graphql_selections
          root_selections = {}
          all_selections = [[nil, nil, root_selections, nil]]
          build_cached_selections(selections, root_selections, all_selections)
          single_selection = nil
          has_merged_selections = false
          all_selections.each do |(type_condition, directives, selections, _child_selections)|
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

        def build_cached_selections(ast_selections, gathered_selections, all_selection_groups)
          ast_selections.each do |node|
            case node
            when GraphQL::Language::Nodes::Field
              key = node.alias || node.name
              if node.directives.any?
                next_sels = @selections_by_node[node]
                next_sels[1] = node.directives
                next_sels[2][key] = node
                all_selection_groups << next_sels
              else
                gathered_selections[key] = node
              end
            when GraphQL::Language::Nodes::InlineFragment
              if node.directives.any? || node.type
                next_sels_config = @selections_by_node[node]
                next_sels_config[0] = node.type
                next_sels_config[1] = node.directives
                build_cached_selections(node.selections, next_sels_config[2], next_sels_config[3])
                all_selection_groups << next_sels_config
                all_selection_groups.concat(next_sels_config[3])
              else
                build_cached_selections(node.selections, gathered_selections, all_selection_groups)
              end
            when GraphQL::Language::Nodes::FragmentSpread
              fragment_def = @query.fragments[node.name]
              next_sels_config = @selections_by_node[node]
              next_sels_config[0] = fragment_def.type
              next_sels_config[1] = node.directives # Use directives from the spread, not the def
              build_cached_selections(fragment_def.selections, next_sels_config[2], next_sels_config[3])
              all_selection_groups << next_sels_config
              all_selection_groups.concat(next_sels_config[3])
            end
          end
        end
      end
    end
  end
end
