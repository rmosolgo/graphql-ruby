# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
      class SelectionsStep
        def initialize(parent_type:, selections:, objects:, results:, runner:, query:, path:)
          @path = path
          @parent_type = parent_type
          @selections = selections
          @runner = runner
          @objects = objects
          @results = results
          @query = query
          @graphql_objects = nil
        end

        attr_reader :path, :query, :objects, :results

        def graphql_objects
          @graphql_objects ||= @objects.map do |obj|
            @parent_type.scoped_new(obj, @query.context)
          end
        end

        def call
          all_selections = [{}, {}]
          @runner.gather_selections(@parent_type, @selections, self, self.query, all_selections, all_selections[1], into: all_selections[0])
          replaced = false
          all_selections.each_slice(2) do |(grouped_selections, prototype_result)|
            if !replaced
              replaced = true
              @results.each { |r| r.replace(prototype_result) }
            else
              # TODO -- this is here to keep response order the same.
              # Should there only be a single prototype_result instead?
              # Or should it not do this here?
              @results.each { |r| r.merge!(prototype_result) }
            end
            if (directives_owner = grouped_selections.delete(:__node))
              directives = directives_owner.directives
              directives.each do |dir_node|
                dir_defn = @runner.runtime_directives[dir_node.name]
                result = case directives_owner
                when Language::Nodes::FragmentSpread
                  dir_defn.resolve_fragment_spread(directives_owner, @parent_type, @objects, self.query.context)
                when Language::Nodes::InlineFragment
                  dir_defn.resolve_inline_fragment(directives_owner, @parent_type, @objects, self.query.context)
                else
                  raise ArgumentError, "Unhandled directive owner (#{directives_owner.class}): #{directives_owner.inspect}"
                end
                if result.is_a?(Finalizer)
                  result.path = path
                end
              end
            end
            grouped_selections.each_value do |frs|
              @runner.add_step(frs)
            end
          end
        end
      end
    end
  end
end
