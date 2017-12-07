# frozen_string_literal: true
require "graphql/language_server/completion_suggestion/item"

module GraphQL
  class LanguageServer
    # This class responds with an array of `Item`s, based on
    # the cursor's `line` and `column` in `text` of `filename`.
    #
    # `server` has the system info, so it's provided here too.
    class CompletionSuggestion
      def initialize(document_position:)
        @document_position = document_position
        @server = document_position.server
      end

      def items
        completion_items = []
        cursor = @document_position.cursor
        if !cursor.graphql?
          return completion_items
        end

        filter = SuggestionFilter.new(cursor.value)
        input_type = cursor.current_input
        self_type = cursor.current_type

        if @@scalar_tokens.include?(cursor.token_name)
          # The cursor is in the middle of a String or other literal;
          # don't provide autocompletes here because it's not GraphQL code
        elsif cursor.variable_type?
          # We're typing the type of a query variable;
          # Suggest input types that match the current token
          @server.input_type_names.each do |input_type_name|
            if filter.match?(input_type_name)
              type = @server.type(input_type_name)
              completion_items << Item.from_type(type: type)
            end
          end
        elsif cursor.fragment_spread_condition?
          # We're typing an inline fragment condition, suggest valid fragment types
          # which overlap with `self_type`
          @server.fields_type_names.each do |fragment_type_name|
            type = @server.type(fragment_type_name)
            if self_type.nil? || GraphQL::Execution::Typecast.subtype?(self_type, type) || GraphQL::Execution::Typecast.subtype?(type, self_type)
              if cursor.value == "on" || filter.match?(fragment_type_name)
                completion_items << Item.from_type(type: type)
              end
            end
          end
        elsif cursor.fragment_definition_condition?
          # We're typing a fragment condition, suggestion valid fragment types
          @server.fields_type_names.each do |fragment_type_name|
            if cursor.value == "on" || filter.match?(fragment_type_name)
              type = @server.type(fragment_type_name)
              completion_items << Item.from_type(type: type)
            end
          end
        elsif cursor.variable_usage?
          # We're typing a variable usage in the query body,
          # make recommendations based on variables defined above.
          # TODO also filter var defs by type, only suggest vars that match the current field
          cursor.each_variable_definition do |var_name, type|
            if cursor.value == "$" || filter.match?(var_name)
              completion_items << Item.from_variable(name: var_name, type: type)
            end
          end
        elsif input_type
          # We're typing an argument, suggest argument names on this field/input obj
          # TODO remove argument names that were already used
          if input_type.respond_to?(:arguments)
            all_args = input_type.arguments
            all_args.each do |name, arg|
              completion_items << Item.from_argument(argument: arg)
            end
          end
        elsif cursor.root?
          # We're at the root level; make root suggestions
          [:query, :mutation, :subscription].each do |t|
            if (type = @server.type(t))
              label = t.to_s
              if filter.match?(label)
                completion_items << Item.from_root(root_type: type)
              end
            end
          end
          if filter.match?("fragment")
            completion_items << Item.from_fragment_token
          end
        elsif self_type
          # We're writing fields; suggest fields on the current `self`
          self_type.all_fields.each do |f|
            if filter.match?(f.name)
              completion_items << Item.from_field(owner: self_type, field: f)
            end
          end
        end

        completion_items
      end

      private

      class SuggestionFilter
        def initialize(value)
          @uniq_chars = value && value.split.uniq
        end

        def match?(label)
          @uniq_chars.nil? || @uniq_chars.all? { |c| label.include?(c) }
        end
      end

      # Use a class variable to avoid warnings when reloading
      @@scalar_tokens = [:STRING, :FLOAT, :INT, :TRUE, :FALSE, :NULL]
    end
  end
end
