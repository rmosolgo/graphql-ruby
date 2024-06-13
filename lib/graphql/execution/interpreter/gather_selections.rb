# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      class GatherSelections
        def initialize(query, selections)
          @query = query
          @selections = selections
          @selections_on_node = Hash.new { |h, k| h[k] = [nil, nil, {}] }
          @selections_on_node.compare_by_identity
        end

        def gather_for(object, type, ast_selections = @selections, selections = nil, &block)
          if selections.nil?
            _type_cond, _dirs, selections = @selections_on_node[nil]
          end

          ast_selections.each do |node|
            case node
            when GraphQL::Language::Nodes::Field
              key = node.alias || node.name
              selections[key] = node
            when GraphQL::Language::Nodes::InlineFragment
              if node.directives.any? || node.type
                next_sels_config = @selections_on_node[node]
                next_sels_config[0] = node.type
                next_sels_config[1] = node.directives
                gather_for(object, type, node.selections, next_sels_config[2])
              else
                gather_for(object, type, node.selections, selections)
              end
            end
          end

          if block_given?
            single_selection = nil
            has_merged_selections = false
            @selections_on_node.each do |_node, (type_condition, _directives, selections)|
              passes_type_condition = if type_condition
                type_defn = @query.get_type(type_condition.name)
                pt = @query.warden.possible_types(type_defn)
                pt.include?(type)
              else
                true
              end

              if passes_type_condition
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
            end

            yield(single_selection)
          end
        end
      end
    end
  end
end
