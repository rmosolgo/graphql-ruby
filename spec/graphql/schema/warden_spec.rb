# frozen_string_literal: true
require "spec_helper"

module MaskHelpers
  PhonemeType = GraphQL::ObjectType.define do
    name "Phoneme"
    description "A building block of sound in a given language"
    metadata :hidden_type, true
    interfaces [LanguageMemberInterface]

    field :name, types.String.to_non_null_type
    field :symbol, types.String.to_non_null_type
    field :languages, LanguageType.to_list_type
    field :manner, MannerEnum
  end

  MannerEnum = GraphQL::EnumType.define do
    name "Manner"
    description "Manner of articulation for this sound"
    metadata :hidden_input_type, true
    value "STOP"
    value "AFFRICATE"
    value "FRICATIVE"
    value "APPROXIMANT"
    value "VOWEL"
    value "TRILL" do
      metadata :hidden_enum_value, true
    end
  end

  LanguageType = GraphQL::ObjectType.define do
    name "Language"
    field :name, types.String.to_non_null_type
    field :families, types.String.to_list_type
    field :phonemes, PhonemeType.to_list_type
    field :graphemes, GraphemeType.to_list_type
  end

  GraphemeType = GraphQL::ObjectType.define do
    name "Grapheme"
    description "A building block of spelling in a given language"
    interfaces [LanguageMemberInterface]

    field :name, types.String.to_non_null_type
    field :glyph, types.String.to_non_null_type
    field :languages, LanguageType.to_list_type
  end

  LanguageMemberInterface = GraphQL::InterfaceType.define do
    name "LanguageMember"
    metadata :hidden_abstract_type, true
    description "Something that belongs to one or more languages"
    field :languages, LanguageType.to_list_type
  end

  EmicUnitUnion = GraphQL::UnionType.define do
    name "EmicUnit"
    description "A building block of a word in a given language"
    possible_types [GraphemeType, PhonemeType]
  end

  WithinInputType = GraphQL::InputObjectType.define do
    name "WithinInput"
    metadata :hidden_input_object_type, true
    argument :latitude, !types.Float
    argument :longitude, !types.Float
    argument :miles, !types.Float do
      metadata :hidden_input_field, true
    end
  end

  QueryType = GraphQL::ObjectType.define do
    name "Query"
    field :languages, LanguageType.to_list_type do
      argument :within, WithinInputType, "Find languages nearby a point"
    end
    field :language, LanguageType do
      metadata :hidden_field, true
      argument :name, !types.String do
        metadata :hidden_argument, true
      end
    end

    field :phonemes, PhonemeType.to_list_type do
      argument :manners, MannerEnum.to_list_type, "Filter phonemes by manner of articulation"
    end

    field :phoneme, PhonemeType do
      description "Lookup a phoneme by symbol"
      argument :symbol, !types.String
    end

    field :unit, EmicUnitUnion do
      description "Find an emic unit by its name"
      argument :name, types.String.to_non_null_type
    end
  end

  Schema = GraphQL::Schema.define do
    query QueryType
    resolve_type -> (obj, ctx) { PhonemeType }
  end

  module Data
    UVULAR_TRILL = OpenStruct.new({name: "Uvular Trill", symbol: "ʀ", manner: "TRILL"})
    def self.unit
      UVULAR_TRILL
    end
  end

  def self.query_with_mask(str, mask, variables: {})
    run_query(str, except: mask, root_value: Data, variables: variables)
  end

  def self.run_query(str, options = {})
    Schema.execute(str, options.merge(root_value: Data))
  end
end


describe GraphQL::Schema::Warden do
  def type_names(introspection_result)
    introspection_result["data"]["__schema"]["types"].map { |t| t["name"] }
  end

  def possible_type_names(type_by_name_result)
    type_by_name_result["possibleTypes"].map { |t| t["name"] }
  end

  def field_type_names(schema_result)
    schema_result["types"]
      .map {|t| t["fields"] }
      .flatten
      .map { |f| f ? get_recursive_field_type_names(f["type"]) : [] }
      .flatten
      .uniq
  end

  def get_recursive_field_type_names(field_result)
    case field_result
    when Hash
      [field_result["name"]].concat(get_recursive_field_type_names(field_result["ofType"]))
    when nil
      []
    else
      raise "Unexpected field result: #{field_result}"
    end
  end

  def error_messages(query_result)
    query_result["errors"].map { |err| err["message"] }
  end

  describe "hiding fields" do
    let(:mask) {
      -> (member, ctx) { member.metadata[:hidden_field] || member.metadata[:hidden_type] }
    }

    it "causes validation errors" do
      query_string = %|{ phoneme(symbol: "ϕ") { name } }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      err_msg = res["errors"][0]["message"]
      assert_equal "Field 'phoneme' doesn't exist on type 'Query'", err_msg

      query_string = %|{ language(name: "Uyghur") { name } }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      err_msg = res["errors"][0]["message"]
      assert_equal "Field 'language' doesn't exist on type 'Query'", err_msg
    end

    it "doesn't show in introspection" do
      query_string = %|
      {
        LanguageType: __type(name: "Language") { fields { name } }
        __schema {
          types {
            name
            fields {
              name
            }
          }
        }
      }|

      res = MaskHelpers.query_with_mask(query_string, mask)

      # Fields dont appear when finding the type by name
      language_fields = res["data"]["LanguageType"]["fields"].map {|f| f["name"] }
      assert_equal ["families", "graphemes", "name"], language_fields

      # Fields don't appear in the __schema result
      phoneme_fields = res["data"]["__schema"]["types"]
        .map { |t| (t["fields"] || []).select { |f| f["name"].start_with?("phoneme") } }
        .flatten

      assert_equal [], phoneme_fields
    end
  end

  describe "hiding types" do
    let(:whitelist) {
      -> (member, ctx) { !member.metadata[:hidden_type] }
    }

    it "hides types from introspection" do
      query_string = %|
      {
        Phoneme: __type(name: "Phoneme") { name }
        EmicUnit: __type(name: "EmicUnit") {
          possibleTypes { name }
        }
        LanguageMember: __type(name: "LanguageMember") {
          possibleTypes { name }
        }
        __schema {
          types {
            name
            fields {
              type {
                name
                ofType {
                  name
                  ofType {
                    name
                  }
                }
              }
            }
          }
        }
      }
      |

      res = MaskHelpers.run_query(query_string, only: whitelist)

      # It's not visible by name
      assert_equal nil, res["data"]["Phoneme"]

      # It's not visible in `__schema`
      all_type_names = type_names(res)
      assert_equal false, all_type_names.include?("Phoneme")

      # No fields return it
      assert_equal false, field_type_names(res["data"]["__schema"]).include?("Phoneme")

      # It's not visible as a union or interface member
      assert_equal false, possible_type_names(res["data"]["EmicUnit"]).include?("Phoneme")
      assert_equal false, possible_type_names(res["data"]["LanguageMember"]).include?("Phoneme")
    end

    it "can't be a fragment condition" do
      query_string = %|
      {
        unit(name: "bilabial trill") {
          ... on Phoneme { name }
          ... f1
        }
      }

      fragment f1 on Phoneme {
        name
      }
      |

      res = MaskHelpers.run_query(query_string, only: whitelist)

      expected_errors = [
        "No such type Phoneme, so it can't be a fragment condition",
        "No such type Phoneme, so it can't be a fragment condition",
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "can't be a resolve_type result" do
      query_string = %|
      {
        unit(name: "Uvular Trill") { __typename }
      }
      |

      assert_raises(GraphQL::UnresolvedTypeError) {
        MaskHelpers.run_query(query_string, only: whitelist)
      }
    end

    describe "hiding an abstract type" do
      let(:mask) {
        -> (member, ctx) { member.metadata[:hidden_abstract_type] }
      }

      it "isn't present in a type's interfaces" do
        query_string = %|
        {
          __type(name: "Phoneme") {
            interfaces { name }
          }
        }
        |

        res = MaskHelpers.query_with_mask(query_string, mask)
        interfaces_names = res["data"]["__type"]["interfaces"].map { |i| i["name"] }
        refute_includes interfaces_names, "LanguageMember"
      end
    end
  end


  describe "hiding arguments" do
    let(:mask) {
      -> (member, ctx) { member.metadata[:hidden_argument] || member.metadata[:hidden_input_type] }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        Query: __type(name: "Query") { fields { name, args { name } } }
      }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)

      query_field_args = res["data"]["Query"]["fields"].each_with_object({}) { |f, memo| memo[f["name"]] = f["args"].map { |a| a["name"] } }
      # hidden argument:
      refute_includes query_field_args["language"], "name"
      # hidden input type:
      refute_includes query_field_args["phoneme"], "manner"
    end

    it "isn't valid in a query" do
      query_string = %|
      {
        language(name: "Catalan") { name }
        phonemes(manners: STOP) { symbol }
      }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = [
        "Field 'language' doesn't accept argument 'name'",
        "Field 'phonemes' doesn't accept argument 'manners'",
      ]
      assert_equal expected_errors, error_messages(res)
    end
  end

  describe "hidding input type arguments" do
    let(:mask) {
      -> (member, ctx) { member.metadata[:hidden_input_field] }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        WithinInput: __type(name: "WithinInput") { inputFields { name } }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      input_field_names = res["data"]["WithinInput"]["inputFields"].map { |f| f["name"] }
      refute_includes input_field_names, "miles"
    end

    it "isn't a valid default value" do
      query_string = %|
      query findLanguages($nearby: WithinInput = {latitude: 1.0, longitude: 2.2, miles: 3.3}) {
        languages(within: $nearby) { name }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = ["Default value for $nearby doesn't match type WithinInput"]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid literal input" do
      query_string = %|
      {
        languages(within: {latitude: 1.0, longitude: 2.2, miles: 3.3}) { name }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = [
        "Argument 'within' on Field 'languages' has an invalid value. Expected type 'WithinInput'.",
        "InputObject 'WithinInput' doesn't accept argument 'miles'"
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid variable input" do
      query_string = %|
      query findLanguages($nearby: WithinInput!) {
        languages(within: $nearby) { name }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask, variables: { "latitude" => 1.0, "longitude" => 2.2, "miles" => 3.3})
      expected_errors = ["Variable nearby of type WithinInput! was provided invalid value"]
      assert_equal expected_errors, error_messages(res)
    end
  end

  describe "hidding input types" do
    let(:mask) {
      -> (member, ctx) { member.metadata[:hidden_input_object_type] }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        WithinInput: __type(name: "WithinInput") { name }
        Query: __type(name: "Query") { fields { name, args { name } } }
        __schema {
          types { name }
        }
      }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)

      assert_equal nil, res["data"]["WithinInput"], "The type isn't accessible by name"

      languages_arg_names = res["data"]["Query"]["fields"].find { |f| f["name"] == "languages" }["args"].map { |a| a["name"] }
      refute_includes languages_arg_names, "within", "Arguments that point to it are gone"

      type_names = res["data"]["__schema"]["types"].map { |t| t["name"] }
      refute_includes type_names, "WithinInput", "It isn't in the schema's types"
    end

    it "isn't a valid input" do
      query_string = %|
      query findLanguages($nearby: WithinInput!) {
        languages(within: $nearby) { name }
      }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = [
        "WithinInput isn't a defined input type (on $nearby)",
        "Field 'languages' doesn't accept argument 'within'",
        "Variable $nearby is declared by findLanguages but not used",
      ]

      assert_equal expected_errors, error_messages(res)
    end
  end

  describe "hiding enum values" do
    let(:mask) {
      -> (member, ctx) { member.metadata[:hidden_enum_value] }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        Manner: __type(name: "Manner") { enumValues { name } }
        __schema {
          types {
            enumValues { name }
          }
        }
      }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)

      manner_values = res["data"]["Manner"]["enumValues"]
        .map { |v| v["name"] }

      schema_values = res["data"]["__schema"]["types"]
        .map { |t| t["enumValues"] || [] }
        .flatten
        .map { |v| v["name"] }

      refute_includes manner_values, "TRILL", "It's not present on __type"
      refute_includes schema_values, "TRILL", "It's not present in __schema"
    end

    it "isn't a valid literal input" do
      query_string = %|
      { phonemes(manners: [STOP, TRILL]) { symbol } }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)
      # It's not a good error message ... but it's something!
      expected_errors = [
        "Argument 'manners' on Field 'phonemes' has an invalid value. Expected type '[Manner]'.",
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid default value" do
      query_string = %|
      query getPhonemes($manners: [Manner] = [STOP, TRILL]){ phonemes(manners: $manners) { symbol } }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = ["Default value for $manners doesn't match type [Manner]"]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid variable input" do
      query_string = %|
      query getPhonemes($manners: [Manner]!) {
        phonemes(manners: $manners) { symbol }
      }
      |
      res = MaskHelpers.query_with_mask(query_string, mask, variables: { "manners" => ["STOP", "TRILL"] })
      # It's not a good error message ... but it's something!
      expected_errors = [
        "Variable manners of type [Manner]! was provided invalid value",
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "raises a runtime error" do
      query_string = %|
      {
        unit(name: "Uvular Trill") { ... on Phoneme { manner } }
      }
      |
      assert_raises(GraphQL::EnumType::UnresolvedValueError) {
        MaskHelpers.query_with_mask(query_string, mask)
      }
    end
  end
end
