# frozen_string_literal: true
module GraphQL
  # Used for defined arguments ({Field}, {InputObjectType})
  #
  # {#name} must be a String.
  #
  # @example defining an argument for a field
  #   GraphQL::Field.define do
  #     # ...
  #     argument :favoriteFood, types.String, "Favorite thing to eat", default_value: "pizza"
  #   end
  #
  # @example defining an argument for an {InputObjectType}
  #   GraphQL::InputObjectType.define do
  #     argument :newName, !types.String
  #   end
  #
  # @example defining an argument with a `prepare` function
  #   GraphQL::Field.define do
  #     argument :userId, types.ID, prepare: ->(userId) do
  #       User.find_by(id: userId)
  #     end
  #   end
  #
  # @example returning an {ExecutionError} from a `prepare` function
  #   GraphQL::Field.define do
  #     argument :date do
  #       type !types.String
  #       prepare ->(date) do
  #         return GraphQL::ExecutionError.new("Invalid date format") unless DateValidator.valid?(date)
  #         Time.zone.parse(date)
  #       end
  #     end
  #   end

  class Argument
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :type, :description, :default_value, :as, :prepare
    attr_accessor :type, :description, :default_value, :name, :as

    ensure_defined(:name, :description, :default_value, :type=, :type, :as, :expose_as, :prepare)

    # @api private
    module DefaultPrepare
      def self.call(value, ctx); value; end
    end

    def initialize
      @prepare_proc = DefaultPrepare
    end

    def initialize_copy(other)
      @expose_as = nil
    end

    def default_value?
      !!@has_default_value
    end

    def default_value=(new_default_value)
      @has_default_value = true
      @default_value = new_default_value
    end

    # @!attribute name
    #   @return [String] The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}

    # @param new_input_type [GraphQL::BaseType, Proc] Assign a new input type for this argument (if it's a proc, it will be called after schema initialization)
    def type=(new_input_type)
      @clean_type = nil
      @dirty_type = new_input_type
    end

    # @return [GraphQL::BaseType] the input type for this argument
    def type
      @clean_type ||= GraphQL::BaseType.resolve_related_type(@dirty_type)
    end

    # @return [String] The name of this argument inside `resolve` functions
    def expose_as
      @expose_as ||= (@as || @name).to_s
    end

    # @param value [Object] The incoming value from variables or query string literal
    # @param ctx [GraphQL::Query::Context]
    # @return [Object] The prepared `value` for this argument or `value` itself if no `prepare` function exists.
    def prepare(value, ctx)
      @prepare_proc.call(value, ctx)
    end

    # Assign a `prepare` function to prepare this argument's value before `resolve` functions are called.
    # @param prepare_proc [#<call(value, ctx)>]
    def prepare=(prepare_proc)
      @prepare_proc = BackwardsCompatibility.wrap_arity(prepare_proc, from: 1, to: 2, name: "Argument#prepare(value, ctx)")
    end

    NO_DEFAULT_VALUE = Object.new
    # @api private
    def self.from_dsl(name, type_or_argument = nil, description = nil, default_value: NO_DEFAULT_VALUE, as: nil, prepare: DefaultPrepare, **kwargs, &block)
      if type_or_argument.is_a?(GraphQL::Argument)
        return type_or_argument.redefine(name: name.to_s)
      end

      argument = if block_given?
        GraphQL::Argument.define(&block)
      else
        GraphQL::Argument.define(**kwargs)
      end

      argument.name = name.to_s
      type_or_argument && argument.type = type_or_argument
      description && argument.description = description
      if default_value != NO_DEFAULT_VALUE
        argument.default_value = default_value
      end
      as && argument.as = as
      if prepare != DefaultPrepare
        argument.prepare = prepare
      end

      argument
    end
  end
end
