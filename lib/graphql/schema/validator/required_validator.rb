# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this validator to require _one_ of the named arguments to be present.
      # Or, use Arrays of symbols to name a valid _set_ of arguments.
      #
      # (This is for specifying mutually exclusive sets of arguments.)
      #
      # @example Require exactly one of these arguments
      #
      #   field :update_amount, IngredientAmount, null: false do
      #     argument :ingredient_id, ID, required: true
      #     argument :cups, Integer, required: false
      #     argument :tablespoons, Integer, required: false
      #     argument :teaspoons, Integer, required: false
      #     validates required: { one_of: [:cups, :tablespoons, :teaspoons] }
      #   end
      #
      # @example Require one of these _sets_ of arguments
      #
      #  field :find_object, Node, null: true do
      #    argument :node_id, ID, required: false
      #    argument :object_type, String, required: false
      #    argument :object_id, Integer, required: false
      #    # either a global `node_id` or an `object_type`/`object_id` pair is required:
      #    validates required: { one_of: [:node_id, [:object_type, :object_id]] }
      #  end
      #
      # @example require _some_ value for an argument, even if it's null
      #   field :update_settings, AccountSettings do
      #     # `required: :nullable` means this argument must be given, but may be `null`
      #     argument :age, Integer, required: :nullable
      #   end
      #
      class RequiredValidator < Validator
        # @param one_of [Symbol, Array<Symbol>] An argument, or a list of arguments, that represents a valid set of inputs for this field
        # @param message [String]
        def initialize(one_of: nil, argument: nil, message: "%{validated} has the wrong arguments", **default_options)
          @one_of = if one_of
            one_of
          elsif argument
            [argument]
          else
            raise ArgumentError, "`one_of:` or `argument:` must be given in `validates required: {...}`"
          end
          @message = message
          super(**default_options)
        end

        def validate(_object, _context, value)
          matched_conditions = 0

          if !value.nil?
            @one_of.each do |one_of_condition|
              case one_of_condition
              when Symbol
                if value.key?(one_of_condition)
                  matched_conditions += 1
                end
              when Array
                if one_of_condition.all? { |k| value.key?(k) }
                  matched_conditions += 1
                  break
                end
              else
                raise ArgumentError, "Unknown one_of condition: #{one_of_condition.inspect}"
              end
            end
          end

          if matched_conditions == 1
            nil # OK
          else
            @message
          end
        end
      end
    end
  end
end
