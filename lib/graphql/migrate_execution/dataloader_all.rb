# frozen_string_literal: true
# rubocop:disable Development/ContextIsPassedCop
module GraphQL
  class MigrateExecution
    class DataloaderAll < Strategy
      DESCRIPTION = <<~DESC
      These fields can use a `dataload:` option.
      DESC

      def add_future(field_definition, new_source)
        inject_field_keyword(new_source, field_definition, :resolve_batch)
        def_node = field_definition.resolver_method.node
        call_node = def_node.body.body.first
        case call_node.name
        when :request, :load
          load_arg_node = call_node.arguments.arguments.first
          with_node = call_node.receiver
          source_class_node, *source_args_nodes = with_node.arguments
        when :dataload
          source_class_node, *source_args_nodes, load_arg_node = call_node.arguments.arguments
        else
          raise ArgumentError, "Unexpected DataloadAll method name: #{def_node.name.inspect}"
        end

        old_load_arg_s = load_arg_node.slice
        new_load_arg_s = case old_load_arg_s
        when "object"
          "objects"
        when /object((\.|\[)[:a-zA-Z0-9_\.\"\'\[\]]+)/
          call_chain = $1
          if /^\.[a-z0-9_A-Z]+$/.match?(call_chain)
            "objects.map(&:#{call_chain[1..-1]})"
          else
            "objects.map { |obj| obj#{call_chain} }"
          end
        else
          raise ArgumentError, "Failed to transform Dataloader argument: #{old_load_arg_s.inspect}"
        end
        new_args = [
          source_class_node.slice,
          *source_args_nodes.map(&:slice),
          new_load_arg_s
        ].join(", ")

        old_method_source = def_node.slice_lines
        new_method_source = old_method_source.sub(/def ([a-z_A-Z0-9]+)(\(|$| )/) do
          is_adding_args = $2.size == 0
          "def self.#{$1}#{is_adding_args ? "(" : $2}objects, context#{is_adding_args ? ")" : ", "}"
        end
        new_method_source.sub!(call_node.slice, "context.dataload_all(#{new_args})")

        combined_new_source = new_method_source + "\n" + old_method_source
        new_source.sub!(old_method_source, combined_new_source)
      end

      def remove_legacy(field_definition, new_source)
        remove_resolver_method(new_source, field_definition)
      end
    end
  end
end
