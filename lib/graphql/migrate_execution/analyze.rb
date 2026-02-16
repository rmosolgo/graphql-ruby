# frozen_string_literal
module GraphQL
  class MigrateExecution
    class Analyze < Action
      def run
        super
        message = "Found #{@total_field_definitions} field definitions:".dup

        @field_definitions_by_strategy.each do |strategy, definitions|
          message << "\n\n#{strategy.name.split("::").last} (#{definitions.size}):"
          max_path = definitions.map { |f| f.path.size }.max + 2
          definitions.each do |field_defn|
            name = field_defn.path.ljust(max_path)
            message << "\n  - #{name} (#{field_defn.resolve_mode.inspect} -> #{field_defn.resolve_mode_key.inspect}) @ #{@path}:#{field_defn.source_line}"
          end
        end

        message
      end
    end
  end
end
