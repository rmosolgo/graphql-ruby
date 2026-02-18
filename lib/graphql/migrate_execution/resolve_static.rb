# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class ResolveStatic < Strategy
      DESCRIPTION = "These can be converted with `resolve_static:`. Dataloader was not detected in these resolver methods."

      def add_future(field_definition, new_source)
        inject_field_keyword(new_source, field_definition, :resolve_static)
        replace_resolver_method(new_source, field_definition, "context")
      end

      def remove_legacy(field_definition, new_source)
        remove_field_keyword(new_source, field_definition, :resolver_method)
        remove_resolver_method(new_source, field_definition)
      end
    end
  end
end
