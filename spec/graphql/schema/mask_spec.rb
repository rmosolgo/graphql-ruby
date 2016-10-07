require "spec_helper"

module MaskHelpers
  PhonemeType = GraphQL::ObjectType.define do
    name "Phoneme"
    metadata :hidden_type, true

    field :name, types.String.to_non_null_type
    field :symbol, types.String.to_non_null_type
    field :languages, LanguageType.to_list_type
  end

  LanguageType = GraphQL::ObjectType.define do
    name "Language"
    field :name, types.String.to_non_null_type
    field :families, types.String.to_list_type
    field :phonemes, PhonemeType.to_list_type
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
  end

  Schema = GraphQL::Schema.define do
    query QueryType
  end
end


describe GraphQL::Schema::Mask do
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
        PhonemeType: __type(name: "Phoneme") { fields { name } }
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

      # The type can't be found by name
      assert_equal nil, res["data"]["PhonemeType"]

      # Fields dont appear when finding the type by name
      language_fields = res["data"]["LanguageType"]["fields"].map {|f| f["name"] }
      assert_equal ["families", "name"], language_fields

      # Fields don't appear in the __schema result
      phoneme_fields = res["data"]["__schema"]["types"]
        .map { |t| (t["fields"] || []).select { |f| f["name"].start_with?("phoneme") } }
        .flatten

      assert_equal [], phoneme_fields
    end
  end
end
