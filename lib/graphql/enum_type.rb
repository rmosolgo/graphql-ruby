module GraphQL
  # Represents a collection of related values.
  # By convention, enum names are `SCREAMING_CASE_NAMES`,
  # but other identifiers are supported too.
  #
  # You can use as return types _or_ as inputs.
  #
  # By default, enums are passed to `resolve` functions as
  # the strings that identify them, but you can provide a
  # custom Ruby value with the `value:` keyword.
  #
  # @example An enum of programming languages
  #   LanguageEnum = GraphQL::EnumType.define do
  #     name "Languages"
  #     description "Programming languages for Web projects"
  #     value("PYTHON", "A dynamic, function-oriented language")
  #     value("RUBY", "A very dynamic language aimed at programmer happiness")
  #     value("JAVASCRIPT", "Accidental lingua franca of the web")
  #   end
  #
  # @example Using an enum as a return type
  #    field :favoriteLanguage, LanguageEnum, "This person's favorite coding language"
  #    # ...
  #    # In a query:
  #    Schema.execute("{ coder(id: 1) { favoriteLanguage } }")
  #    # { "data" => { "coder" => { "favoriteLanguage" => "RUBY" } } }
  #
  # @example Defining an enum input
  #    field :coders, types[CoderType] do
  #      argument :knowing, types[LanguageType]
  #      resolve ->(obj, args, ctx) {
  #        Coder.where(language: args[:knowing])
  #      }
  #    end
  #
  # @example Using an enum as input
  #   {
  #     # find coders who know Python and Ruby
  #     coders(knowing: [PYTHON, RUBY]) {
  #       name
  #       hourlyRate
  #     }
  #   }
  #
  # @example Enum whose values are different in Ruby-land
  #   GraphQL::EnumType.define do
  #     # ...
  #     # use the `value:` keyword:
  #     value("RUBY", "Lisp? Smalltalk?", value: :rb)
  #   end
  #
  #   # Now, resolve functions will receive `:rb` instead of `"RUBY"`
  #   field :favoriteLanguage, LanguageEnum
  #   resolve ->(obj, args, ctx) {
  #     args[:favoriteLanguage] # => :rb
  #   }
  #
  class EnumType < GraphQL::BaseType
    accepts_definitions :values, value: GraphQL::Define::AssignEnumValue

    def initialize
      @values_by_name = {}
      @values_by_value = {}
    end

    # @param new_values [Array<EnumValue>] The set of values contained in this type
    def values=(new_values)
      @values_by_name = {}
      @values_by_value = {}
      new_values.each { |enum_value| add_value(enum_value) }
    end

    # @param enum_value [EnumValue] A value to add to this type's set of values
    def add_value(enum_value)
      @values_by_name[enum_value.name] = enum_value
      @values_by_value[enum_value.value] = enum_value
    end

    # @return [Hash<String => EnumValue>] `{name => value}` pairs contained in this type
    def values
      ensure_defined
      @values_by_name
    end

    def kind
      GraphQL::TypeKinds::ENUM
    end

    def validate_non_null_input(value_name)
      ensure_defined
      result = GraphQL::Query::InputValidationResult.new

      if !@values_by_name.key?(value_name)
        result.add_problem("Expected #{JSON.dump(value_name)} to be one of: #{@values_by_name.keys.join(', ')}")
      end

      result
    end

    # Get the underlying value for this enum value
    #
    # @example get episode value from Enum
    #   episode = EpisodeEnum.coerce("NEWHOPE")
    #   episode # => 6
    #
    # @param value_name [String] the string representation of this enum value
    # @return [Object] the underlying value for this enum value
    def coerce_non_null_input(value_name)
      ensure_defined
      if @values_by_name.key?(value_name)
        @values_by_name.fetch(value_name).value
      else
        nil
      end
    end

    def coerce_result(value)
      ensure_defined
      @values_by_value.fetch(value).name
    end

    def to_s
      name
    end

    # A value within an {EnumType}
    #
    # Created with the `value` helper
    class EnumValue
      def self.define(name:, description: nil, deprecation_reason: nil, value: nil)
        new(name: name, description: description, deprecation_reason: deprecation_reason, value: value)
      end

      attr_accessor :name, :description, :deprecation_reason, :value
      def initialize(name:, description:, deprecation_reason:, value:)
        @name = name
        @description = description
        @deprecation_reason = deprecation_reason
        @value = value
      end
    end
  end
end
