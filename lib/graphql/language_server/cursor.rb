# frozen_string_literal: true
require "graphql/language_server/cursor/scanner"
require "graphql/language_server/cursor/state_machine"
require "graphql/language_server/cursor/fragment_def"
require "graphql/language_server/cursor/fragment_spread"
require "graphql/language_server/cursor/variable_def"
require "graphql/language_server/cursor/language_scope"
require "graphql/language_server/cursor/self_stack"
require "graphql/language_server/cursor/input_stack"

module GraphQL
  class LanguageServer
    class Cursor
      attr_reader :current_type, :current_input, :value, :token_name

      def initialize(current_type:, current_input:, current_token:, var_def_state:, fragment_def_state:, fragment_spread_state:, root:, graphql: true)
        @current_type = current_type
        @current_input = current_input
        if current_token
          @value = current_token.value
          @token_name = current_token.name
        else
          @value = nil
          @token_name = nil
        end
        @root = root
        @var_def_state = var_def_state
        @fragment_def_state = fragment_def_state
        @fragment_spread_state = fragment_spread_state
        @graphql = graphql
      end

      # If false, then the cursor was out-of-scope
      def graphql?
        @graphql
      end

      def root?
        @root
      end

      def variable_type?
        @var_def_state.state == :type_name
      end

      def variable_usage?
        @var_def_state.ended? && (@var_def_state.state == :var_sign || @var_def_state.state == :var_name)
      end

      def each_variable_definition
        @var_def_state.defined_variables.each do |var_name|
          var_type = @var_def_state.defined_variable_types[var_name]
          yield(var_name, var_type)
        end
        nil
      end

      def fragment_definition_condition?
        @fragment_def_state.state == :type_name || @fragment_def_state.state == :on
      end

      def fragment_spread_condition?
        @fragment_spread_state.state == :type_name || @fragment_spread_state.state == :on
      end

      def self.fetch(filename:, text:, line:, column:, server:)
        scanner = Scanner.new(filename: filename, text: text, line: line, column: column, server: server)
        scanner.cursor
      end

      # @see {#graphql?}
      # @return [Cursor] Represents an out-of-scope cursor position
      def self.out_of_scope
        self.new(
          current_type: nil,
          current_input: nil,
          current_token: nil,
          var_def_state: nil,
          fragment_def_state: nil,
          fragment_spread_state: nil,
          root: nil,
          graphql: false,
        )
      end
    end
  end
end
