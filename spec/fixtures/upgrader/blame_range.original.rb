# frozen_string_literal: true

module Platform
  module Objects
    BlameRange = GraphQL::ObjectType.define do
      name "BlameRange"
      description "Represents a range of information from a Git blame."

      scopeless_tokens_as_minimum


      interfaces [
        Interfaces::A,
        Interfaces::B,
      ]

      field :startingLine, !types.Int do
        description "The starting line for the range"

        resolve ->(range, args, context) {
          range.lines.first[:lineno]
        }
      end

      field :endingLine, !types.Int do
        description "The ending line for the range"

        resolve ->(range, args, context) {
          range.lines.first[:lineno] + (range.lines.length - 1)
        }
      end

      field :commit, -> { !Objects::Commit } do
        description "Identifies the line author"
      end

      field :age, !types.Int do
        description "Identifies the recency of the change, from 1 (new) to 10 (old). This is calculated as a 2-quantile and determines the length of distance between the median age of all the changes in the file and the recency of the current range's change."
        property :scale
      end
    end
  end
end
