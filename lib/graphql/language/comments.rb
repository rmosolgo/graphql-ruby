# frozen_string_literal: true
module GraphQL
  module Language
    module Comments
      extend self

      def commentize(description, indent: '')
        lines = description.split("\n")

        comment = ''.dup

        lines.each do |line|
          if line == ''
            comment << "#{indent}#\n"
          else
            sublines = break_line(line, 120 - indent.length)
            sublines.each do |subline|
              comment << "#{indent}# #{subline}\n"
            end
          end
        end

        comment
      end

      private

      def break_line(line, length)
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
