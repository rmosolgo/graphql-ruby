# frozen_string_literal: true
module GraphQL
  module Language
    module Comment
      def self.print(str, indent: '')
        lines = []
        str.split("\n") do |line|
          comment_str = "".dup
          comment_str << indent
          comment_str << "# "
          comment_str << line
          lines << comment_str
        end
        lines.join("\n") + "\n"
      end
    end
  end
end
