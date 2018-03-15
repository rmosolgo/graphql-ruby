# frozen_string_literal: true

# Here's the "application"
module Jazz
  module Models
    Instrument = Struct.new(:name, :family)
    Ensemble = Struct.new(:name)
    Musician = Struct.new(:name, :favorite_key)
    Key = Struct.new(:root, :sharp, :flat) do
      def self.from_notation(key_str)
        key, sharp_or_flat = key_str.split("")
        sharp = sharp_or_flat ==  "♯"
        flat = sharp_or_flat == "♭"
        Models::Key.new(key, sharp, flat)
      end

      def to_notation
        "#{root}#{sharp ? "♯" : ""}#{flat ? "♭" : ""}"
      end
    end

    def self.reset
      @data = {
        "Instrument" => [
          Models::Instrument.new("Banjo", :str),
          Models::Instrument.new("Flute", "WOODWIND"),
          Models::Instrument.new("Trumpet", "BRASS"),
          Models::Instrument.new("Piano", "KEYS"),
          Models::Instrument.new("Organ", "KEYS"),
          Models::Instrument.new("Drum Kit", "PERCUSSION"),
        ],
        "Ensemble" => [
          Models::Ensemble.new("Bela Fleck and the Flecktones"),
        ],
        "Musician" => [
          Models::Musician.new("Herbie Hancock", Models::Key.from_notation("B♭")),
        ]
      }
    end

    def self.data
      @data || reset
    end
  end

  class BaseArgument < GraphQL::Schema::Argument
    def initialize(name, type, desc = nil, custom: nil, **kwargs)
      @custom = custom
      super(name, type, desc, **kwargs)
    end

    def to_graphql
      arg_defn = super
      arg_defn.metadata[:custom] = @custom
      arg_defn
    end
  end

  # A custom field class that supports the `upcase:` option
  class BaseField < GraphQL::Schema::Field
    argument_class BaseArgument
    def initialize(*args, **options, &block)
      @upcase = options.delete(:upcase)
      super(*args, **options, &block)
    end

    def to_graphql
      field_defn = super
      if @upcase
        inner_resolve = field_defn.resolve_proc
        field_defn.resolve = ->(obj, args, ctx) {
          inner_resolve.call(obj, args, ctx).upcase
        }
      end
      field_defn
    end
  end

  class BaseObject < GraphQL::Schema::Object
    # Use this overridden field class
    field_class BaseField

    class << self
      def config(key, value)
        configs[key] = value
      end

      def configs
        @configs ||= {}
      end

      def to_graphql
        type_defn = super
        configs.each do |k,v|
          type_defn.metadata[k] = v
        end
        type_defn
      end
    end
  end

  class BaseInterface < GraphQL::Schema::Interface
    # Use this overridden field class
    field_class BaseField
  end

  class BaseEnumValue < GraphQL::Schema::EnumValue
    def initialize(*args, custom_setting: nil, **kwargs, &block)
      @custom_setting = custom_setting
      super(*args, **kwargs, &block)
    end

    def to_graphql
      enum_value_defn = super
      enum_value_defn.metadata[:custom_setting] = @custom_setting
      enum_value_defn
    end
  end

  class BaseEnum < GraphQL::Schema::Enum
    enum_value_class BaseEnumValue
  end

  # Some arbitrary global ID scheme
  # *Type suffix is removed automatically
  class GloballyIdentifiableType < BaseInterface
    description "A fetchable object in the system"
    field :id, ID, "A unique identifier for this object", null: false
    field :upcased_id, ID, null: false, upcase: true, method: :id

    module Implementation
      def id
        GloballyIdentifiableType.to_id(@object)
      end
    end

    def self.to_id(object)
      "#{object.class.name.split("::").last}/#{object.name}"
    end

    def self.find(id)
      class_name, object_name = id.split("/")
      Models.data[class_name].find { |obj| obj.name == object_name }
    end
  end

  # A legacy-style interface used by new-style types
  NamedEntity = GraphQL::InterfaceType.define do
    name "NamedEntity"
    field :name, !types.String
  end

  # test field inheritance
  class ObjectWithUpcasedName < BaseObject
    # Test extra arguments:
    field :upcase_name, String, null: false, upcase: true

    def upcase_name
      object.name # upcase is applied by the superclass
    end
  end

  # Here's a new-style GraphQL type definition
  class Ensemble < ObjectWithUpcasedName
    implements GloballyIdentifiableType, NamedEntity
    description "A group of musicians playing together"
    config :config, :configged
    # Test string type names:
    field :name, "String", null: false
    field :musicians, "[Jazz::Musician]", null: false
    field :formed_at, String, null: true, hash_key: "formedAtDate"
  end

  class Family < BaseEnum
    description "Groups of musical instruments"
    # support string and symbol
    value "STRING", "Makes a sound by vibrating strings", value: :str, custom_setting: 1
    value :WOODWIND, "Makes a sound by vibrating air in a pipe"
    value :BRASS, "Makes a sound by amplifying the sound of buzzing lips"
    value "PERCUSSION", "Makes a sound by hitting something that vibrates"
    value "DIDGERIDOO", "Makes a sound by amplifying the sound of buzzing lips", deprecation_reason: "Merged into BRASS"
    value "KEYS" do
      description "Neither here nor there, really"
    end
  end

  # Lives side-by-side with an old-style definition
  using GraphQL::DeprecatedDSL # for ! and types[]
  InstrumentType = GraphQL::ObjectType.define do
    name "Instrument"
    interfaces [NamedEntity]
    implements GloballyIdentifiableType

    field :id, !types.ID, "A unique identifier for this object", resolve: ->(obj, args, ctx) { GloballyIdentifiableType.to_id(obj) }
    field :upcasedId, !types.ID, resolve: ->(obj, args, ctx) { GloballyIdentifiableType.to_id(obj).upcase }
    if RUBY_ENGINE == "jruby"
      # JRuby doesn't support refinements, so the `using` above won't work
      field :family, Family.to_non_null_type
    else
      field :family, !Family
    end
  end

  class Key < GraphQL::Schema::Scalar
    description "A musical key"
    def self.coerce_input(val, ctx)
      Models::Key.from_notation(val)
    end

    def self.coerce_result(val, ctx)
      val.to_notation
    end
  end

  class Musician < BaseObject
    implements GloballyIdentifiableType
    implements NamedEntity
    description "Someone who plays an instrument"
    field :instrument, InstrumentType, null: false do
      description "An object played in order to produce music"
    end
    field :favorite_key, Key, null: true
    # Test lists with nullable members:
    field :inspect_context, [String, null: true], null: false
    field :add_error, String, null: false, extras: [:execution_errors]
    def inspect_context
      [
        @context.custom_method,
        @context[:magic_key],
        @context[:normal_key],
        nil,
      ]
    end

    def add_error(execution_errors:)
      execution_errors.add("this has a path")
      "done"
    end
  end

  LegacyInputType = GraphQL::InputObjectType.define do
    name "LegacyInput"
    argument :intValue, !types.Int
  end

  class InspectableInput < GraphQL::Schema::InputObject
    argument :string_value, String, required: true, description: "Test description kwarg"
    argument :nested_input, InspectableInput, required: false
    argument :legacy_input, LegacyInputType, required: false
    def helper_method
      [
        # Context is available in the InputObject
        context[:message],
        # A GraphQL::Query::Arguments instance is available
        arguments[:stringValue],
        # Legacy inputs have underscored method access too
        legacy_input ? legacy_input.int_value : "-",
        # Access by method call is available
        "(#{nested_input ? nested_input.helper_method : "-"})",
      ].join(", ")
    end
  end

  class InspectableKey < BaseObject
    field :root, String, null: false
    field :is_sharp, Boolean, null: false, method: :sharp
    field :is_flat, Boolean, null: false, method: :flat
  end

  class PerformingAct < GraphQL::Schema::Union
    possible_types Musician, Ensemble

    def self.resolve_type(object, context)
      if object.is_a?(Models::Ensemble)
        Ensemble
      else
        Musician
      end
    end
  end

  # Another new-style definition, with method overrides
  class Query < BaseObject
    field :ensembles, [Ensemble], null: false
    field :find, GloballyIdentifiableType, null: true do
      argument :id, ID, required: true
    end
    field :instruments, [InstrumentType], null: false do
      argument :family, Family, required: false
    end
    field :inspect_input, [String], null: false do
      argument :input, InspectableInput, required: true, custom: :ok
    end
    field :inspect_key, InspectableKey, null: false do
      argument :key, Key, required: true
    end
    field :nowPlaying, PerformingAct, null: false, resolve: ->(o, a, c) { Models.data["Ensemble"].first }
    # For asserting that the object is initialized once:
    field :object_id, Integer, null: false
    field :inspect_context, [String], null: false
    field :hashyEnsemble, Ensemble, null: false

    def ensembles
      Models.data["Ensemble"]
    end

    def find(id:)
      if id == "MagicalSkipId"
        context.skip
      else
        GloballyIdentifiableType.find(id)
      end
    end

    def instruments(family: nil)
      objs = Models.data["Instrument"]
      if family
        objs = objs.select { |i| i.family == family }
      end
      objs
    end

    # This is for testing input object behavior
    def inspect_input(input:)
      [
        input.class.name,
        input.helper_method,
        # Access by method
        input.string_value,
        # Access by key:
        input["stringValue"],
        input[:stringValue],
      ]
    end

    def inspect_key(key:)
      key
    end

    def inspect_context
      [
        context.custom_method,
        context[:magic_key],
        context[:normal_key]
      ]
    end

    def hashy_ensemble
      # Both string and symbol keys are supported:

      {
          name: "The Grateful Dead",
          "musicians" => [
            OpenStruct.new(name: "Jerry Garcia"),
          ],
          "formedAtDate" => "May 5, 1965",
      }
    end
  end

  class EnsembleInput < GraphQL::Schema::InputObject
    argument :name, String, required: true
  end

  class AddInstrument < GraphQL::Schema::Mutation
    description "Register a new musical instrument in the database"

    argument :name, String, required: true
    argument :family, Family, required: true

    field :instrument, InstrumentType, null: false

    def perform(name:, family:)
      instrument = Jazz::Models::Instrument.new(name, family)
      Jazz::Models.data["Instrument"] << instrument
      { instrument: instrument }
    end
  end

  class RenameInstrument < GraphQL::Schema::FancyMutation
    description "Rename an instrument"
    argument :id, ID, required: true, inject: :instrument
    argument :new_name, String, required: true

    # It gets `field :user_errors` automatically, should we
    # require `null: true` here?
    field :instrument, InstrumentType, null: true

    def instrument(id)
      # We're turning the id into an index
      instrument = Jazz::Models.data["Instrument"][id.to_i]
      if instrument.nil?
        raise GraphQL::UserError, "Instrument not found for #{id.inspect}"
      end
      # Make like a promise:
      Box.new(instrument)
    end

    def before_mutate(instrument:, new_name:)
      if instrument.name == new_name
        raise GraphQL::UserError, "Can't rename an instrument to the same name"
      end
    end

    def mutate(instrument:, new_name:)
      if instrument.name == "Piano"
        raise GraphQL::UserError, "Can't rename Piano"
      end
      instrument.name = new_name
      { instrument: instrument }
    end
  end

  class Mutation < BaseObject
    field :add_ensemble, Ensemble, null: false do
      argument :input, EnsembleInput, required: true
    end

    field :add_instrument, mutation: AddInstrument
    field :rename_instrument, mutation: RenameInstrument

    def add_ensemble(input:)
      ens = Models::Ensemble.new(input.name)
      Models.data["Ensemble"] << ens
      ens
    end
  end

  class MetadataPlugin
    def self.use(schema_defn, value:)
      schema_defn.target.metadata[:plugin_key] = value
    end
  end

  class CustomContext < GraphQL::Query::Context
    def [](key)
      if key == :magic_key
        "magic_value"
      else
        super
      end
    end

    def custom_method
      "custom_method"
    end
  end

  module Introspection
    class TypeType < GraphQL::Introspection::TypeType
      def name
        object.name.upcase
      end
    end

    class SchemaType < GraphQL::Introspection::SchemaType
      graphql_name "__Schema"

      field :is_jazzy, Boolean, null: false
      def is_jazzy
        true
      end
    end

    class DynamicFields < GraphQL::Introspection::DynamicFields
      field :__typename_length, Int, null: false, extras: [:irep_node]
      field :__ast_node_class, String, null: false, extras: [:ast_node]
      def __typename_length(irep_node:)
        __typename(irep_node: irep_node).length
      end

      def __ast_node_class(ast_node:)
        ast_node.class.name
      end
    end

    class EntryPoints < GraphQL::Introspection::EntryPoints
      field :__classname, String, "The Ruby class name of the root object", null: false
      def __classname
        object.class.name
      end
    end
  end

  # Like a Promise, but even more boring,
  # because the value was actually already calculated.
  class Box
    attr_reader :content
    def initialize(content)
      @content = content
    end
  end

  # New-style Schema definition
  class Schema < GraphQL::Schema
    query(Query)
    mutation(Mutation)
    context_class CustomContext
    introspection(Introspection)
    lazy_resolve(Box, :content)
    use MetadataPlugin, value: "xyz"
    def self.resolve_type(type, obj, ctx)
      class_name = obj.class.name.split("::").last
      ctx.schema.types[class_name] || raise("No type for #{obj.inspect}")
    end
  end
end
