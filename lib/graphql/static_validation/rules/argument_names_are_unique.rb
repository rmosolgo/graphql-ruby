# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module ArgumentNamesAreUnique
      include GraphQL::StaticValidation::Error::ErrorHelper

      def on_field(node, parent)
        validate_arguments(node)
        super
      end

      def on_directive(node, parent)
        validate_arguments(node)
        super
      end

      def validate_arguments(node)
        argument_defns = node.arguments
        if argument_defns.size > 1
          seen = {}
          argument_defns.each do |a|
            name = a.name
            if seen.key?(name)
              prev = seen[name]
              if prev.is_a?(Array)
                prev << a
              else
                seen[name] = [prev, a]
              end
            else
              seen[name] = a
            end
          end
          seen.each do |name, val|
            if val.is_a?(Array)
              add_error(GraphQL::StaticValidation::ArgumentNamesAreUniqueError.new("There can be only one argument named \"#{name}\"", nodes: val, name: name))
            end
          end
        end
      end
    end
  end
end
