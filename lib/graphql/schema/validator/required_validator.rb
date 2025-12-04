# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this validator to require _one_ of the named arguments to be present.
      # Or, use Arrays of symbols to name a valid _set_ of arguments.
      #
      # (This is for specifying mutually exclusive sets of arguments.)
      #
      # If you use {GraphQL::Schema::Visibility} to hide all the arguments in a `one_of: [..]` set,
      # then a developer-facing {GraphQL::Error} will be raised during execution. Pass `allow_all_hidden: true` to
      # skip validation in this case instead.
      #
      # This validator also implements `argument ... required: :nullable`. If an argument has `required: :nullable`
      # but it's hidden with {GraphQL::Schema::Visibility}, then this validator doesn't run.
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
        # @param one_of [Array<Symbol>] A list of arguments, exactly one of which is required for this field
        # @param argument [Symbol] An argument that is required for this field
        # @param allow_all_hidden [Boolean] If `true`, then this validator won't run if all the `one_of: ...` arguments have been hidden
        # @param message [String]
        def initialize(one_of: nil, argument: nil, allow_all_hidden: nil, message: nil, **default_options)
          @one_of = if one_of
            one_of
          elsif argument
            [ argument ]
          else
            raise ArgumentError, "`one_of:` or `argument:` must be given in `validates required: {...}`"
          end
          @allow_all_hidden = allow_all_hidden.nil? ? !!argument : allow_all_hidden
          @message = message
          super(**default_options)
        end

        def validate(_object, context, value)
          fully_matched_conditions = 0
          partially_matched_conditions = 0

          visible_keywords = context.types.arguments(@validated).map(&:keyword)
          no_visible_conditions = true

          if !value.nil?
            @one_of.each do |one_of_condition|
              case one_of_condition
              when Symbol
                if no_visible_conditions && visible_keywords.include?(one_of_condition)
                  no_visible_conditions = false
                end

                if value.key?(one_of_condition)
                  fully_matched_conditions += 1
                end
              when Array
                any_match = false
                full_match = true

                one_of_condition.each do |k|
                  if no_visible_conditions && visible_keywords.include?(k)
                    no_visible_conditions = false
                  end
                  if value.key?(k)
                    any_match = true
                  else
                    full_match = false
                  end
                end

                partial_match = !full_match && any_match

                if full_match
                  fully_matched_conditions += 1
                end

                if partial_match
                  partially_matched_conditions += 1
                end
              else
                raise ArgumentError, "Unknown one_of condition: #{one_of_condition.inspect}"
              end
            end
          end

          if no_visible_conditions
            if @allow_all_hidden
              return nil
            else
              raise GraphQL::Error, <<~ERR
                #{@validated.path} validates `required: ...` but all required arguments were hidden.

                Update your schema definition to allow the client to see some fields or skip validation by adding `required: { ..., allow_all_hidden: true }`
              ERR
            end
          end

          if fully_matched_conditions == 1 && partially_matched_conditions == 0
            nil # OK
          else
            @message || build_message(context)
          end
        end

        def build_message(context)
          argument_definitions = context.types.arguments(@validated)

          required_names = @one_of.map do |arg_keyword|
            if arg_keyword.is_a?(Array)
              names = arg_keyword.map { |arg| arg_keyword_to_graphql_name(argument_definitions, arg) }
              names.compact! # hidden arguments are `nil`
              "(" + names.join(" and ") + ")"
            else
              arg_keyword_to_graphql_name(argument_definitions, arg_keyword)
            end
          end
          required_names.compact! # remove entries for hidden arguments


          case required_names.size
          when 0
            # The required definitions were hidden from the client.
            # Another option here would be to raise an error in the application....
            "%{validated} is missing a required argument."
          when 1
            "%{validated} must include the following argument: #{required_names.first}."
          else
            "%{validated} must include exactly one of the following arguments: #{required_names.join(", ")}."
          end
        end

        def arg_keyword_to_graphql_name(argument_definitions, arg_keyword)
          argument_definition = argument_definitions.find { |defn| defn.keyword == arg_keyword }
          argument_definition&.graphql_name
        end
      end
    end
  end
end
