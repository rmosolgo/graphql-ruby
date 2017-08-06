# frozen_string_literal: true
module GraphQL
  class Schema
    module BuildFromDefinition
      # Apply `accepts_definitions` functions from the schema IDL.
      #
      # Each macro is converted to a definition function call,
      # then removed from the description.
      #
      # __WARNING!!__ The inputs are passed to `instance_eval`,
      # So never pass user input to this instrumenter.
      # If you do this, a malicious user could wipe your servers.
      #
      # @example Equivalent IDL definition
      #   # A programming language
      #   # @authorize role: :admin
      #   type Language {
      #     # This field is implemented by calling `language_name`
      #     # @property :language_name
      #     name: String!
      #   }
      #
      # @example Equivalent Ruby DSL definition
      #   Types::LanguageType = GraphQL::ObjectType.define do
      #     name "Language"
      #     description "A programming language"
      #     authorize(role: :admin)
      #     field :name, !types.String, property: :language_name
      #   end
      #
      module DefineInstrumentation
        # This is pretty clugy, it just finds the function name
        # and the arguments, then uses them to eval if a matching function is found.
        PATTERN = /^\@(.*)$/

        # @param target [<#redefine, #description>]
        def self.instrument(target)
          if target.description.nil?
            target
          else
            defns = target.description.scan(PATTERN)
            if defns.any?
              target.redefine {
                instance_eval(defns.join("\n"))
                description(target.description.gsub(PATTERN, "").strip)
              }
            else
              target
            end
          end
        end
      end
    end
  end
end
