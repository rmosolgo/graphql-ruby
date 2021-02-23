# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class Argument
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :type, :description, :default_value, :as, :prepare, :method_access, :deprecation_reason
    attr_reader :default_value
    attr_accessor :description, :name, :as, :deprecation_reason
    attr_accessor :ast_node
    attr_accessor :method_access
    alias :graphql_name :name

    ensure_defined(:name, :description, :default_value, :type=, :type, :as, :expose_as, :prepare, :method_access, :deprecation_reason)

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

    def method_access?
      # Treat unset as true -- only `false` should override
      @method_access != false
    end

    def default_value=(new_default_value)
      if new_default_value == NO_DEFAULT_VALUE
        @has_default_value = false
        @default_value = nil
      else
        @has_default_value = true
        @default_value = GraphQL::Argument.deep_stringify(new_default_value)
      end
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

    # Backport this to support legacy-style directives
    def keyword
      @keyword ||= GraphQL::Schema::Member::BuildType.underscore(expose_as).to_sym
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

    def type_class
      metadata[:type_class]
    end

    NO_DEFAULT_VALUE = Object.new
    # @api private
    def self.from_dsl(name, type_or_argument = nil, description = nil, default_value: NO_DEFAULT_VALUE, as: nil, prepare: DefaultPrepare, **kwargs, &block)
      name_s = name.to_s

      # Move some positional args into keywords if they're present
      description && kwargs[:description] ||= description
      kwargs[:name] ||= name_s
      kwargs[:default_value] ||= default_value
      kwargs[:as] ||= as

      unless prepare == DefaultPrepare
        kwargs[:prepare] ||= prepare
      end

      if !type_or_argument.nil? && !type_or_argument.is_a?(GraphQL::Argument)
        # Maybe a string, proc or BaseType
        kwargs[:type] = type_or_argument
      end

      if type_or_argument.is_a?(GraphQL::Argument)
        type_or_argument.redefine(**kwargs, &block)
      else
        GraphQL::Argument.define(**kwargs, &block)
      end
    end

    # @api private
    def self.deep_stringify(val)
      case val
      when Array
        val.map { |v| deep_stringify(v) }
      when Hash
        new_val = {}
        val.each do |k, v|
          new_val[k.to_s] = deep_stringify(v)
        end
        new_val
      else
        val
      end
    end
  end
end
