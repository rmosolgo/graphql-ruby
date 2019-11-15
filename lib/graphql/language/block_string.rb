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
        while lines.size > 0 && lines[0].empty?
          lines.shift
        end
        while lines.size > 0 && lines[-1].empty?
          lines.pop
        end

        # Rebuild the string
        lines.join("\n")
      end

      def self.print(str, indent: '')
        lines = str.split("\n")

        block_str = "#{indent}\"\"\"\n".dup

        lines.each do |line|
          if line == ''
            block_str << "\n"
          else
            sublines = break_line(line, 120 - indent.length)
            sublines.each do |subline|
              block_str << "#{indent}#{subline}\n"
            end
          end
        end

        block_str << "#{indent}\"\"\"\n".dup
      end

      private

      def self.break_line(line, length)
        return [line] if line.length < length + 5

        parts = line.split(Regexp.new("((?: |^).{15,#{length - 40}}(?= |$))"))
        return [line] if parts.length < 4

        sublines = [parts.slice!(0, 3).join]

        parts.each_with_index do |part, i|
          next if i % 2 == 1
          sublines << "#{part[1..-1]}#{parts[i + 1]}"
        end

        sublines
      end
    end
  end
end
