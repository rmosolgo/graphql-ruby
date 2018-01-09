# frozen_string_literal: true

module Platform
  module Objects
    class BlameRange < Types::BaseObject
      description "Represents a range of information from a Git blame."

      scopeless_tokens_as_minimum

      field :starting_line, Integer, description: "The starting line for the range", null: false do
        resolve ->(range, args, context) {
          range.lines.first[:lineno]
        }
      end

      field :ending_line, Integer, description: "The ending line for the range", null: false do
        resolve ->(range, args, context) {
          range.lines.first[:lineno] + (range.lines.length - 1)
        }
      end

      field :commit, -> { Objects::Commit }, description: "Identifies the line author", null: false

      field :age, Integer, method: :scale, description: "Identifies the recency of the change, from 1 (new) to 10 (old). This is calculated as a 2-quantile and determines the length of distance between the median age of all the changes in the file and the recency of the current range's change.", null: false
    end
  end
end
