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

  QueryType = GraphQL::ObjectType.define do
    name "Query"
    field :languages, LanguageType.to_list_type
    field :language, LanguageType do
      metadata :hidden_field, true
      argument :name, !types.String
    end
    field :phonemes, PhonemeType.to_list_type
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
    resolve_type(:stub)
  end
end


describe GraphQL::Schema::Mask do
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
      raise "Unexpected field result: #{field_resul}"
    end
  end

  describe "#visible?" do
    let(:mask) {
      # Hide all name fields
      GraphQL::Schema::Mask.new(schema: MaskHelpers::Schema) do |member|
        member.name == "name"
      end
    }

    it "returns true for members which _aren't_ excluded" do
      assert_equal true, mask.visible?(MaskHelpers::QueryType.fields["languages"])
      assert_equal true, mask.visible?(MaskHelpers::LanguageType.fields["phonemes"])
    end

    it "returns false for excluded members" do
      assert_equal false, mask.visible?(MaskHelpers::LanguageType.fields["name"])
      assert_equal false, mask.visible?(MaskHelpers::PhonemeType.fields["name"])
    end
  end

  describe "#hidden_field?" do
    let(:mask) {
      GraphQL::Schema::Mask.new(schema: MaskHelpers::Schema) do |member|
        member.metadata[:hidden_field] || member.metadata[:hidden_type]
      end
    }

    it "hides fields which are excluded" do
      assert_equal true, mask.hidden_field?(MaskHelpers::QueryType.fields["language"])
      assert_equal false, mask.hidden_field?(MaskHelpers::QueryType.fields["languages"])
    end

    it "hides fields whose return types are excluded" do
      assert_equal true, mask.hidden_field?(MaskHelpers::LanguageType.fields["phonemes"])
      assert_equal true, mask.hidden_field?(MaskHelpers::QueryType.fields["phonemes"])
      assert_equal true, mask.hidden_field?(MaskHelpers::QueryType.fields["phoneme"])

      assert_equal false, mask.hidden_field?(MaskHelpers::LanguageType.fields["name"])
      assert_equal false, mask.hidden_field?(MaskHelpers::LanguageType.fields["families"])
    end

    it "causes validation errors" do
      query_string = %|{ phoneme(symbol: "ϕ") { name } }|
      res = mask.execute(query_string)
      err_msg = res["errors"][0]["message"]
      assert_equal "Field 'phoneme' doesn't exist on type 'Query'", err_msg

      query_string = %|{ language(name: "Uyghur") { name } }|
      res = mask.execute(query_string)
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

      res = mask.execute(query_string)

      # Fields dont appear when finding the type by name
      language_fields = res["data"]["LanguageType"]["fields"].map {|f| f["name"] }
      assert_equal ["families", "graphemes", "name"], language_fields

      # Fields don't appear in the __schema result
      phoneme_fields = res["data"]["__schema"]["types"]
        .map { |t| (t["fields"] || []).select { |f| f["name"].start_with?("phoneme") } }
        .flatten

      assert_equal [], phoneme_fields
    end

    it "isn't present in a schema print-out"
  end

  describe "#hidden_type?" do
    let(:mask) {
      GraphQL::Schema::Mask.new(schema: MaskHelpers::Schema) do |member|
        member.metadata[:hidden_type]
      end
    }

    it "returns true for masked types" do
      assert_equal true, mask.hidden_type?(MaskHelpers::PhonemeType)
      assert_equal false, mask.hidden_type?(MaskHelpers::LanguageType)
    end

    it "removes items from Schema#possible_types" do
      # It's in the plain schema:
      assert_equal true, MaskHelpers::Schema.possible_types(MaskHelpers::EmicUnitUnion).include?(MaskHelpers::PhonemeType)
      # But not the mask:
      assert_equal false, mask.possible_types(MaskHelpers::EmicUnitUnion).include?(MaskHelpers::PhonemeType)
    end

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

      res = mask.execute(query_string)

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

    describe "hiding an abstract type" do
      let(:mask) {
        GraphQL::Schema::Mask.new(schema: MaskHelpers::Schema) do |member|
          member.metadata[:hidden_abstract_type]
        end
      }

      it "isn't present in a type's interfaces" do
        query_string = %|
        {
          __type(name: "Phoneme") {
            interfaces { name }
          }
        }
        |

        res = mask.execute(query_string)
        interfaces_names = res["data"]["__type"]["interfaces"].map { |i| i["name"] }
        refute_includes interfaces_names, "LanguageMember"
      end
    end

    it "isn't present in a schema print-out" do
      schema_print = GraphQL::Schema::Printer.print_schema(MaskHelpers::Schema)
      mask_print = GraphQL::Schema::Printer.print_schema(mask)
      assert_includes schema_print, "Phoneme"
      refute_includes mask_print, "Phoneme"
    end
  end


  describe "#hidden_argument?" do
    it "is hidden if the input type is hidden"
    it "is hidden if the argument is hidden"
    it "isn't present in introspection"
    it "isn't valid in a query"
    it "isn't present in a schema print-out"
  end

  describe "#hidden_input_object_type?" do
    it "isn't present in a schema print-out"
    it "isn't present in introspection"
    it "isn't a valid input"
  end

  describe "#hidden_enum_value?" do
    it "isn't present in introspection"
    it "isn't a valid return value"
    it "isn't a valid input"
    it "isn't present in a schema print-out"
  end
end
