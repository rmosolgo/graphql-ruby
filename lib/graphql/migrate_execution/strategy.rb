# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class Strategy
      def add_future(field_definition, new_source)
      end

      def remove_legacy(field_definition, new_source)
      end

      private

      def inject_field_keyword(new_source, field_definition, keyword)
        field_definition_source = field_definition.source
        value = field_definition.future_resolve_shorthand
        new_definition_source = if field_definition_source[/[a-z_]+:/]
          field_definition_source.sub(/field(.*) ([a-z_]+:.*)$/, "field\\1 #{keyword}: #{value.inspect}, \\2")
        else
          field_definition_source + ", #{keyword}: #{value.inspect}"
        end
        new_source.sub!(field_definition_source, new_definition_source)
      end

      def remove_field_keyword(new_source, field_definition, keyword)
        field_definition_source = field_definition.source
        new_definition_source = field_definition_source.sub(/, #{keyword}: \S+( |$)/, "\\1")
        new_source.sub!(field_definition_source, new_definition_source)
      end

      def replace_resolver_method(new_source, field_definition, new_params)
        resolver_method = field_definition.resolver_method
        method_name = resolver_method.name
        old_method = resolver_method.source
        new_class_method = old_method
          .sub("def ", 'def self.')

        if resolver_method.parameter_names.empty?
          new_class_method.sub!(method_name.to_s, "#{method_name}(#{new_params})")
        else
          new_class_method.sub!("def self.#{method_name}(", "def self.#{method_name}(#{new_params}, ")
        end

        old_lines = old_method.split("\n")
        new_body = old_lines.first[/^ +/] + "  self.class.#{method_name}(#{new_params}#{resolver_method.parameter_names.map { |n| ", #{n}: #{n}"}.join})"
        new_inst_method = [old_lines.first, new_body, old_lines.last].join("\n")

        new_double_definition = new_class_method + "\n" + new_inst_method + "\n"
        new_source.sub!(old_method, new_double_definition)
      end

      def remove_resolver_method(new_source, field_definition)
        new_source.sub!(field_definition.resolver_method.source + "\n", "")
      end
    end
  end
end
