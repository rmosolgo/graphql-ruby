# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      class GatherSelections
        def initialize(query)
          @query = query
          @selections_by_node = Hash.new { |h, ast_node|
          # TODO dedicated class for storage
            h[ast_node] = [nil, nil, {}, nil]
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
          all_selections = []
          build_cached_selections(selections, nil, all_selections)
          single_selection = nil
          multiple_selections = nil
          has_merged_selections = false
          all_selections.each do |(type_condition, directives, selections, child_selections)|
            runtime_dirs = nil
            if type_condition
              type_defn = @query.get_type(type_condition.name)
              pt = @query.warden.possible_types(type_defn)
              if !pt.include?(type)
                # These selections failed type condition
                next
              end
            end

            if directives&.any?
              passes_dirs = true
              directives.each do |dir_node|
                dir_defn = @schema_directives.fetch(dir_node.name)
                args = if dir_defn.arguments_statically_coercible?
                  @query.arguments_for(dir_node, dir_defn)
                else
                  # The arguments must be prepared in the context of the given object
                  @query.arguments_for(dir_node, dir_defn, parent_object: object)
                end

                if !dir_defn.include?(object, args, @query.context)
                  passes_dirs = false
                  break
                end

                if @runtime_directive_names.include?(dir_node.name)
                  runtime_dirs ||= []
                  runtime_dirs << dir_node
                end
              end
              if !passes_dirs
                # Skipped by directives
                next
              end
            end

            if runtime_dirs && child_selections
              # Don't include runtime directives with single fields here;
              # That's not how the runtime code expects it to be.
              if multiple_selections.nil?
                multiple_selections = []
                if single_selection
                  multiple_selections << single_selection
                end
              end
              selections[:graphql_directives] = runtime_dirs
              multiple_selections << selections
            else
              if single_selection.nil?
                single_selection = selections
                if multiple_selections
                  multiple_selections << single_selection
                end
              else
                if has_merged_selections == false
                  idx = multiple_selections&.index(single_selection)
                  single_selection = single_selection.dup
                  if idx
                    multiple_selections[idx] = single_selection
                  end
                  has_merged_selections = true
                end
                single_selection.merge!(selections)
              end
            end
          end

          if multiple_selections
            multiple_selections.each do |sel|
              yield(sel, true)
            end
          elsif single_selection # Maybe `nil` if all were skipped
            yield(single_selection)
          end
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
                if gathered_selections.nil?
                  gathered_selections = {}
                  all_selection_groups << [nil, nil, gathered_selections, nil]
                end
                gathered_selections[key] = node
              end
            when GraphQL::Language::Nodes::InlineFragment
              if node.directives.any? || node.type
                next_sels_config = @selections_by_node[node]
                next_sels_config[0] = node.type
                next_sels_config[1] = node.directives
                next_sels_config[3] = []
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
              next_sels_config[3] = []
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
