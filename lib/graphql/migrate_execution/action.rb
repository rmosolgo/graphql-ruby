# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class Action
      def initialize(migration, path, source)
        @migration = migration
        @path = path
        @source = source
        @type_definitions = Hash.new { |h, k| h[k] = TypeDefinition.new(k) }
        @field_definitions_by_strategy = Hash.new { |h, k| h[k] = [] }
        @total_field_definitions = 0
      end

      def run
        parse_result = Prism.parse(@source, filepath: @path)
        visitor = Visitor.new(@source, @type_definitions)
        visitor.visit(parse_result.value)
        @type_definitions.each do |name, type_defn|
          type_defn.field_definitions.each do |f_name, f_defn|
            @total_field_definitions += 1
            f_defn.check_for_resolver_method
            @field_definitions_by_strategy[f_defn.migration_strategy] << f_defn
          end
        end
        nil
      end

      private

      def call_method_on_strategy(method_name)
        new_source = @source.dup
        @field_definitions_by_strategy.each do |strategy_class, field_definitions|
          strategy = strategy_class.new
          field_definitions.each do |field_defn|
            strategy.public_send(method_name, field_defn, new_source)
          end
        end
        new_source
      end
    end
  end
end
