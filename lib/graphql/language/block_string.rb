# frozen_string_literal: true
# typed: strict
module GraphQL
  module Language
    module BlockString
      # Remove leading and trailing whitespace from a block string.
      # See "Block Strings" in https://github.com/facebook/graphql/blob/master/spec/Section%202%20--%20Language.md
      #: (String str) -> String
      def self.trim_whitespace(str)
        # Early return for the most common cases:
        if str == ""
          return "".dup
        elsif !(has_newline = str.include?("\n")) && !(str.start_with?(" "))
          return str
        end

        lines = has_newline ? str.split("\n") : [str]
        common_indent = nil #: Integer?

        # find the common whitespace
        lines.each_with_index do |line, idx|
          if idx == 0
            next
          end
          line_length = line.size
          leading = 0
          while leading < line_length && line.getbyte(leading) == 32
            leading += 1
          end
          if leading < line_length && (common_indent.nil? || leading < common_indent)
            common_indent = leading
          end
        end

        # Remove the common whitespace
        if common_indent && common_indent > 0
          lines.each_with_index do |line, idx|
            if idx == 0
              next
            else
              line[0, common_indent] = ""
            end
          end
        end

        # Remove leading & trailing blank lines
        while (first_line = lines.first) && contains_only_whitespace?(first_line)
          lines.shift
        end
        while (last_line = lines.last) && contains_only_whitespace?(last_line)
          lines.pop
        end

        # Rebuild the string
        lines.size > 1 ? lines.join("\n") : (lines.first || "".dup)
      end

      #: (String str, ?indent: String) -> String
      def self.print(str, indent: '')
        line_length = 120 - indent.length
        block_str = "".dup
        triple_quotes = "\"\"\"\n"
        block_str << indent
        block_str << triple_quotes

        if str.include?("\n")
          str.split("\n") do |line|
            if line == ''
              block_str << "\n"
            else
              break_line(line, line_length) do |subline|
                block_str << indent
                block_str << subline
                block_str << "\n"
              end
            end
          end
        else
          break_line(str, line_length) do |subline|
            block_str << indent
            block_str << subline
            block_str << "\n"
          end
        end

        block_str << indent
        block_str << triple_quotes
      end

      private

      #: (String line, Integer length) { (String) -> void } -> void
      def self.break_line(line, length, &block)
        return yield(line) if line.length < length + 5

        parts = line.split(Regexp.new("((?: |^).{15,#{length - 40}}(?= |$))"))
        return yield(line) if parts.length < 4

        # `parts` has at least 4 items:
        first_parts = parts.slice!(0, 3) #: as !nil
        yield(first_parts.join)

        parts.each_with_index do |part, i|
          next if i % 2 == 1
          yield "#{part[1..-1]}#{parts[i + 1]}"
        end

        nil
      end

      #: (String line) -> bool
      def self.contains_only_whitespace?(line)
        line.match?(/^\s*$/)
      end
    end
  end
end
