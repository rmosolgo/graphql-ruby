# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class CompletionSuggestion
      class Item
        attr_reader :label, :detail, :documentation, :kind, :insert_text

        def initialize(label:, detail:, insert_text: nil, documentation:, kind:)
          @label = label
          @detail = detail
          @insert_text = insert_text
          @documentation = documentation
          @kind = kind
        end

        def self.from_field(owner:, field:)
          self.new(
            label: field.name,
            detail: "#{owner.name}.#{field.name}",
            documentation: "#{field.description} (#{field.type.to_s})",
            kind: LSP::Constant::CompletionItemKind::FIELD,
          )
        end

        def self.from_fragment_token
          self.new(
            label: "fragment",
            detail: nil,
            documentation: "Add a new typed fragment",
            kind: LSP::Constant::CompletionItemKind::KEYWORD,
          )
        end

        def self.from_root(root_type:)
          self.new(
            label: root_type.name.downcase,
            detail: "#{root_type.name}!",
            documentation: root_type.description,
            kind: LSP::Constant::CompletionItemKind::KEYWORD,
          )
        end

        def self.from_argument(argument:)
          self.new(
            label: argument.name,
            insert_text: "#{argument.name}:",
            detail: argument.type.to_s,
            documentation: argument.description,
            kind: LSP::Constant::CompletionItemKind::FIELD,
          )
        end

        def self.from_variable(name:, type:)
          # TODO: list & non-null wrappers here
          # TODO include default values as documentation
          self.new(
            label: "$#{name}",
            insert_text: name,
            detail: type,
            documentation: "query variable",
            kind: LSP::Constant::CompletionItemKind::VARIABLE,
          )
        end

        def self.from_type(type:)
          self.new(
            label: type.name,
            detail: type.name,
            documentation: type.description,
            kind: LSP::Constant::CompletionItemKind::CLASS,
          )
        end
      end
    end
  end
end
