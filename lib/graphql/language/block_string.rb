# frozen_string_literal: true
module GraphQL
  module Language
    module BlockString
      # Remove leading and trailing whitespace from a block string.
      # See "Block Strings" in https://github.com/facebook/graphql/blob/master/spec/Section%202%20--%20Language.md
      def self.trim_whitespace(str)
        lines = str.split("\n")
        common_indent = nil

        # find the common whitespace
        lines.each_with_index do |line, idx|
          if idx == 0
            next
          end
          line_length = line.size
          line_indent = line[/\A */].size
          if line_indent < line_length && (common_indent.nil? || line_indent < common_indent)
            common_indent = line_indent
          end
        end

        # Remove the common whitespace
        if common_indent
          lines.each_with_index do |line, idx|
            if idx == 0
              next
            else
              line[0, common_indent] = ""
            end
          end
        end

        # Remove leading & trailing blank lines
        while lines.first.empty?
          lines.shift
        end
        while lines.last.empty?
          lines.pop
        end

        # Rebuild the string
        lines.join("\n")
      end
    end
  end
end
