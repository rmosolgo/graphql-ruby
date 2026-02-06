# frozen_string_literal: true
require "prism"
require "pp"
require "graphql/migrate_execution/field_definition"
require "graphql/migrate_execution/resolver_method"
require "graphql/migrate_execution/type_definition"
require "graphql/migrate_execution/visitor"

module GraphQL
  class MigrateExecution
    NOT_CONFIGURED = Object.new
    def initialize(filepath)
      @filepath = filepath
    end

    def run
      source = File.read(@filepath)
      parse_result = Prism.parse(source)
      visitor = Visitor.new(source)
      visitor.visit(parse_result.value)

      field_definitions_by_strategy = Hash.new { |h, k| h[k] = [] }

      total_defns = 0
      visitor.type_definitions.each do |name, type_defn|
        type_defn.field_definitions.each do |f_name, f_defn|
          total_defns += 1
          field_definitions_by_strategy[f_defn.migration_strategy] << f_defn
        end
      end

      puts "Found #{total_defns} field definitions:"
      field_definitions_by_strategy.each do |strategy, definitions|
        puts "\n#{strategy} (#{definitions.size}):"
        max_path = definitions.map { |f| f.path.size }.max + 2
        definitions.each do |field_defn|
          name = field_defn.path.ljust(max_path)
          puts "  - #{name} (#{field_defn.resolve_mode.inspect} -> #{field_defn.resolve_mode_key.inspect}) @ #{@filepath}:#{field_defn.source_line}"
        end
      end
    end
  end
end
