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

      # TODO: do I actually want to add this?
      def metadata(key, value)
        @target.metadata[key] = value
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
