# Based on the graphql-js example
# https://github.com/graphql/graphql-js/blob/master/src/__tests__/starWarsSchema.js
require_relative './star_wars_data'

EpisodeEnum = GraphQL::EnumType.new do |e|
  e.name("Episode")
  e.description("One of the films in the Star Wars Trilogy.")

  e.value("NEWHOPE",  "Released in 1977", value: 4)
  e.value("EMPIRE",   "Released in 1980", value: 5)
  e.value("JEDI",     "Released in 1983", value: 6)
end

CharacterInterface = GraphQL::InterfaceType.new do |i, types, field|
  i.name("Character")
  i.description("A character in the Star Wars Trilogy.")

  i.fields({
    id: field.build(type: !types.String, desc: "The id of the character."),
    name: field.build(type: types.String, desc: "The name of the Character."),
    friends: field.build(type: types[i], desc: "The friends of the character, or an empty list if they have none."),
    appearsIn: field.build(type: types[EpisodeEnum], desc: "Which movies they appear in."),
  })
end

HumanType = GraphQL::ObjectType.new do |t, types, field|
  t.name("Human")
  t.description("A humanoid creature in the Star Wars universe.")
  t.fields({
    id: field.build(type: !types.String, desc: "The id of the human."),
    name: field.build(type: types.String, desc: "The name of the human."),
    friends: GraphQL::Field.new { |f|
      f.type(types[CharacterInterface])
      f.description("The friends of the human, or an empty list if they have none.")
      f.resolve(GET_FRIENDS)
    },
    appearsIn: field.build(type: types[EpisodeEnum], desc: "Which movies they appear in."),
    homePlanet: field.build(type: types.String, desc: "The home planet of the human, or null if unknown."),
  })
  t.interfaces([CharacterInterface])
end

DroidType = GraphQL::ObjectType.new do |t, types, field|
  t.name("Droid")
  t.description("A mechanical creature in the Star Wars universe.")
  t.fields({
    id: field.build(type: !types.String, desc: "The id of the droid."),
    name: field.build(type: types.String, desc: "The name of the droid."),
    friends: GraphQL::Field.new { |f|
      f.type(types[CharacterInterface])
      f.description("The friends of the droid, or an empty list if they have none.")
      f.resolve(GET_FRIENDS)
    },
    appearsIn: field.build(type: types[EpisodeEnum], desc: "Which movies they appear in."),
    primaryFunction: field.build(type: types.String, desc: "The primary function of the droid."),
  })
  t.interfaces([CharacterInterface])
end

class FindRecordField < GraphQL::Field
  def initialize(type, data)
    @data = data
    self.type = type
    self.arguments = {
      id: GraphQL::Argument.new(type: !GraphQL::STRING_TYPE, description: "The id of the #{type.name}.")
    }
  end

  def resolve(obj, args, ctx)
    @data[args["id"]]
  end
end


StarWarsQueryType = GraphQL::ObjectType.new do |t, types, field, arg|
  t.name("Query")
  t.fields({
    hero: GraphQL::Field.new { |f|
      f.arguments({
        episode: arg.build(type: EpisodeEnum, desc: "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode"),
      })
      f.resolve -> (obj, args, ctx) { args["episode"] == 5 ? luke : artoo }
    },
    human: FindRecordField.new(HumanType, HUMAN_DATA),
    droid: FindRecordField.new(DroidType, DROID_DATA),
  })
end
