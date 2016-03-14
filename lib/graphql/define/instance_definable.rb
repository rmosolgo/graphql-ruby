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

      module ClassMethods
        # Define an instance of this class using its {.definitions}.
        def define(&block)
          instance = self.new
          proxy = DefinedObjectProxy.new(instance, dictionary)
          block && proxy.instance_eval(&block)
          instance
        end

        # Attach definitions to this class.
        # Each symbol in `accepts` will be assigned with `{key}=`.
        # The last entry in accepts may be a hash of name-proc pairs for custom definitions.
        def accepts_definitions(*accepts)
          @own_dictionary = own_dictionary.merge(AssignmentDictionary.create(*accepts))
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
