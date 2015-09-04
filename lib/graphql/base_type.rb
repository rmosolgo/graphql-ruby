module GraphQL
  # The parent for all type classes.
  class BaseType
    include GraphQL::DefinitionHelpers::NonNullWithBang
    include GraphQL::DefinitionHelpers::DefinedByConfig

    # @param other [GraphQL::BaseType] compare to this object
    # @return [Boolean] are these types equivalent? (incl. non-null, list)
    def ==(other)
      if other.is_a?(GraphQL::BaseType)
        self.to_s == other.to_s
      else
        super
      end
    end

    # If this type is modifying an underlying type,
    # return the underlying type. (Otherwise, return `self`.)
    def unwrap
      self
    end

    module ModifiesAnotherType
      def unwrap
        self.of_type.unwrap
      end
    end

    # Print the human-readable name of this type
    def to_s
      Printer.instance.print(self)
    end

    alias :inspect :to_s

    # Print a type, using the query-style naming pattern
    class Printer
      include Singleton
      def print(type)
        if type.kind.non_null?
          "#{print(type.of_type)}!"
        elsif type.kind.list?
          "[#{print(type.of_type)}]"
        else
          type.name
        end
      end
    end
  end
end
