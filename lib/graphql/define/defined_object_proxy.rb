module GraphQL
  module Define
    class DefinedObjectProxy
      def initialize(target)
        @target = target
        @dictionary = target.class.dictionary
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

      def respond_to_missing?(name, include_private = false)
        return true if @dictionary[name]
        super
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
