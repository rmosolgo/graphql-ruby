# frozen_string_literal: true

# Here's the "application"
module Jazz
  module Models
    Instrument = Struct.new(:name, :family)
    Ensemble = Struct.new(:name)
  end
  DATA = {
    "Instrument" => [
      Models::Instrument.new("Banjo", :str),
      Models::Instrument.new("Flute", "WOODWIND"),
      Models::Instrument.new("Trumpet", "BRASS"),
      Models::Instrument.new("Piano", "KEYS"),
      Models::Instrument.new("Organ", "KEYS"),
      Models::Instrument.new("Drum Kit", "PERCUSSION"),
    ],
    "Ensemble" => [
      Models::Ensemble.new("Bela Fleck and the Flecktones")
    ],
  }

  # Some arbitrary global ID scheme
  module GloballyIdentifiable
    class Interface < GraphQL::Interface
      graphql_name "GloballyIdentifiable"
      description "A fetchable object in the system"
      field :id, "ID", "A unique identifier for this object", null: false
    end

    def self.included(child)
      child.class_eval do
        implements GloballyIdentifiable::Interface
        field :id, "ID", null: false
      end
    end

    def id
      GloballyIdentifiable.to_id(@object)
    end

    def self.to_id(object)
      "#{object.class.name.split("::").last}/#{object.name}"
    end

    def self.find(id)
      class_name, object_name = id.split("/")
      DATA[class_name].find { |obj| obj.name == object_name }
    end
  end

  # Here's a new-style GraphQL type definition
  class Ensemble < GraphQL::Object
    include GloballyIdentifiable
    description "A group of musicians playing together"
    field :name, "String", null: false
    field :musicians, "[Jazz::Musician]", null: false
  end

  class Family < GraphQL::Enum
    description "Groups of musical instruments"
    # support string and symbol
    value "STRING", "Makes a sound by vibrating strings", value: :str
    value :WOODWIND, "Makes a sound by vibrating air in a pipe"
    value :BRASS, "Makes a sound by amplifying the sound of buzzing lips"
    value "PERCUSSION", "Makes a sound by hitting something that vibrates"
    value "KEYS", "Neither here nor there, really"
    value "DIDGERIDOO", "Makes a sound by amplifying the sound of buzzing lips", deprecation_reason: "Merged into BRASS"
  end

  # Lives side-by-side with an old-style definition
  using GraphQL::DeprecatedDSL # for ! and types[]
  InstrumentType = GraphQL::ObjectType.define do
    name "Instrument"
    implements GloballyIdentifiable::Interface
    field :id, !types.ID, "A unique identifier for this object", resolve: ->(obj, args, ctx) { GloballyIdentifiable.to_id(obj) }
    field :name, !types.String
    field :family, !Family
  end

  class Musician < GraphQL::Object
    include GloballyIdentifiable
    description "Someone who plays an instrument"
    field :name, String, null: false
    field :instrument, InstrumentType, null: false
  end

  # Another new-style definition, with method overrides
  class Query < GraphQL::Object
    field :ensembles, [Ensemble], null: false
    field :find, GloballyIdentifiable::Interface, null: true do
      argument :id, "ID", null: false
    end
    field :instruments, [InstrumentType], null: false do
      argument :family, Family, null: true
    end

    def ensembles
      DATA["Ensemble"]
    end

    def find(id:)
      GloballyIdentifiable.find(id)
    end

    def instruments(family: nil)
      objs = DATA["Instrument"]
      if family
        objs = objs.select { |i| i.family == family }
      end
      objs
    end
  end

  # New-style Schema definition
  class Schema < GraphQL::Schema
    query(Query)

    def self.resolve_type(type, obj, ctx)
      class_name = obj.class.name.split("::").last
      ctx.schema.types[class_name]
    end
  end
end
