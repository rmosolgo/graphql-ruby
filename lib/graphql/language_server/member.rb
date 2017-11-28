# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # A catch-all object for graphql data in the language server.
    # Holds types, fields, arguments and input_fields.
    class Member
      def initialize(data_hash)
        @name = data_hash["name"]
        @description = data_hash["description"]
        @type = data_hash["type"]
        @fields = reduce_by_name(data_hash["fields"])
        @arguments = reduce_by_name(data_hash["inputFields"] || data_hash["args"])
      end

      attr_reader :name, :description, :type, :fields, :arguments

      # @return [String, nil]
      def returns(name)
        f = @fields[name]
        f && get_inner_type_name(f.type)
      end

      def accepts(arg_name)
        a = @arguments[name]
        a && get_inner_type_name(a.type)
      end

      private

      def get_inner_type_name(type)
        while (inner_type = type["ofType"])
          type = inner_type
        end
        type["name"]
      end

      def reduce_by_name(items)
        items ||= []
        items.each_with_object({}) do |i, memo|
          memo[i["name"]] = self.class.new(i)
        end
      end
    end
  end
end
