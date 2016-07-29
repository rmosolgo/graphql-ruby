module GraphQL
  module Define
    # This module provides the `.define { ... }` API for {GraphQL::BaseType}, {GraphQL::Field}, {GraphQL::Argument} and {GraphQL::Directive}.
    #
    # The goals are:
    # - Minimal overhead in consuming classes
    # - Independence between consuming classes
    # - Extendable by third-party libraries without monkey-patching or other nastiness
    #
    # @example Make a class definable
    #   class Car
    #     attr_accessor :make, :model, :all_wheel_drive
    #
    #     accepts_definitions(
    #       # These attrs will be defined with plain setters, `{attr}=`
    #       :make, :model,
    #       # This attr has a custom definition which applies the config to the target
    #       doors: -> (car, doors_count) { doors_count.times { car.doors << Door.new } }
    #     )
    #   end
    #
    #   # Create an instance with `.define`:
    #   subaru_baja = Car.define do
    #     make "Subaru"
    #     model "Baja"
    #     doors 4
    #   end
    #
    #   # The custom proc was applied:
    #   subaru_baja.doors #=> [<Door>, <Door>, <Door>, <Door>]
    #
    # @example Extending the definition of a class
    #   # Add some definitions:
    #   Car.accepts_definitions(:all_wheel_drive)
    #
    #   # Use it in a definition
    #   subaru_baja = Car.define do
    #     # ...
    #     all_wheel_drive true
    #   end
    #
    module InstanceDefinable
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Set the definition block for this instance.
      # It can be run later with {#ensure_defined}
      def definition_proc=(defn_block)
        @definition_proc = defn_block
      end

      private

      # Run the definition block if it hasn't been run yet.
      # This can only be run once: the block is deleted after it's used.
      # You have to call this before using any value which could
      # come from the definition block.
      # @return [void]
      def ensure_defined
        if @definition_proc
          defn_proc = @definition_proc
          @definition_proc = nil
          proxy = DefinedObjectProxy.new(self)
          proxy.instance_eval(&defn_proc)
        end
        nil
      end

      module ClassMethods
        # Prepare the defintion for an instance of this class using its {.definitions}.
        # Note that the block is not called right away -- instead, it's deferred until
        # one of the defined fields is needed.
        def define(**kwargs, &block)
          instance = self.new

          instance.definition_proc = -> (obj) {
            kwargs.each do |keyword, value|
              public_send(keyword, value)
            end

            if block
              instance_eval(&block)
            end
          }

          instance
        end

        # Attach definitions to this class.
        # Each symbol in `accepts` will be assigned with `{key}=`.
        # The last entry in accepts may be a hash of name-proc pairs for custom definitions.
        def accepts_definitions(*accepts)
          @own_dictionary = own_dictionary.merge(AssignmentDictionary.create(*accepts))
        end

        # Define a reader and writer for each of `attr_names` which
        # ensures that the definition block was called before accessing it.
        def lazy_defined_attr_accessor(*attr_names)
          attr_names.each do |attr_name|
            ivar_name = :"@#{attr_name}"
            define_method(attr_name) do
              ensure_defined
              instance_variable_get(ivar_name)
            end

            define_method("#{attr_name}=") do |new_value|
              ensure_defined
              instance_variable_set(ivar_name, new_value)
            end
          end
        end

        # @return [Hash] combined definitions for self and ancestors
        def dictionary
          if superclass.respond_to?(:dictionary)
            own_dictionary.merge(superclass.dictionary)
          else
            own_dictionary
          end
        end

        # @return [Hash] definitions for this class only
        def own_dictionary
          @own_dictionary ||= {}
        end
      end
    end
  end
end
