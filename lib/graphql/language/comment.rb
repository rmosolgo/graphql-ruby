# frozen_string_literal: true
module GraphQL
  module Language
    module Comment
      def self.print(str, indent: '')
        comment_str = "".dup
        comment_str << indent
        comment_str << "# "
        comment_str << str
        comment_str << "\n"
      end
    end
  end
end
