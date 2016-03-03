# Based on the graphql-js example
# https://github.com/graphql/graphql-js/blob/master/src/__tests__/starWarsSchema.js
require_relative "./star_wars_data"

EpisodeEnum = GraphQL::EnumType.define do
  name("Episode")
  description("One of the films in the Star Wars Trilogy.")

  value("NEWHOPE",  "Released in 1977", value: 4)
  value("EMPIRE",   "Released in 1980", value: 5)
  value("JEDI",     "Released in 1983", value: 6)
end

CharacterInterface = GraphQL::InterfaceType.define do
  name("Character")
  description("A character in the Star Wars Trilogy.")

  field :id, !types.String, "The id of the character."
  field :name, types.String, "The name of the Character."
  field :friends, -> { types[CharacterInterface] }, "The friends of the character, or an empty list if they have none."
  field :appearsIn, types[EpisodeEnum], "Which movies they appear in."
end

HumanType = GraphQL::ObjectType.define do
  name("Human")
  description("A humanoid creature in the Star Wars universe.")
  field :id, !types.String, "The id of the human."
  field :name, types.String, "The name of the human."
  field :friends do
    type(types[CharacterInterface])
    description("The friends of the human, or an empty list if they have none.")
    resolve(GET_FRIENDS)
  end
  field :appearsIn, types[EpisodeEnum], "Which movies they appear in."
  field :homePlanet, types.String, "The home planet of the human, or null if unknown."

  interfaces([CharacterInterface])
end

DroidType = GraphQL::ObjectType.define do
  name("Droid")
  description("A mechanical creature in the Star Wars universe.")
  field :id, !types.String, "The id of the droid."
  field :name, types.String, "The name of the droid."
  field :friends do
    type(types[CharacterInterface])
    description("The friends of the droid, or an empty list if they have none.")
    resolve(GET_FRIENDS)
  end
  field :appearsIn, types[EpisodeEnum], "Which movies they appear in."
  field :primaryFunction, types.String, "The primary function of the droid."

  interfaces([CharacterInterface])
end

class FindRecordField
  def self.create(return_type, data)
    GraphQL::Field.define do
      type(return_type)
      argument :id, !types.String, "The id of the #{return_type.name}."
      resolve -> (obj, args, ctx) { data[args["id"]] }
    end
  end
end


StarWarsQueryType = GraphQL::ObjectType.define do
  name("Query")
  field :hero do
    argument :episode, EpisodeEnum,  "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode"
    resolve -> (obj, args, ctx) { args["episode"] == 5 ? luke : artoo }
  end

  field :human, field: FindRecordField.create(HumanType, HUMAN_DATA)
  field :droid, field: FindRecordField.create(DroidType, DROID_DATA)
end
