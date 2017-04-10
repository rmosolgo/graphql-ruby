module GraphQL
  class Schema
    module DefaultRenamer
      def self.rename_field(field)
        field
      end

      def self.rename_argument(argument)
        argument
      end
    end
  end
end
