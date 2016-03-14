module GraphQL
  module Define
    class DefinedObjectProxy
      def initialize(target, dictionary)
        @target = target
        @dictionary = dictionary
      end

      def types
        GraphQL::Define::TypeDefiner.instance
      end

      def method_missing(name, *args, &block)
        definition = @dictionary[name]
        if definition
          definition.call(@target, *args, &block)
        else
          p "Failed to find config #{name} in #{inspect}"
          super
        end
      end

      def to_s
        inspect
      end

      def inspect
        "<DefinedObjectProxy #{@target} (#{@dictionary.keys})>"
      end
    end
  end
end
