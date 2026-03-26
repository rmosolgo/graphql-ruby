# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FieldsWillMerge do
  include StaticValidationHelpers

  let(:schema) {
    GraphQL::Schema.from_definition(%|
      type Query {
        dog: Dog
        cat: Cat
        pet: Pet
        toy: Toy
        animal: Animal
      }

      union Animal = Dog \| Cat

      type Mutation {
        registerPet(params: PetParams): Pet
      }

      enum PetCommand {
        SIT
        HEEL
        JUMP
        DOWN
      }

      enum ToySize {
        SMALL
        LARGE
      }

      enum PetSpecies {
        DOG
        CAT
      }

      input PetParams {
        name: String!
        species: PetSpecies!
      }

      interface Mammal {
        name(surname: Boolean = false): String!
        nickname: String
      }

      interface Pet {
        name(surname: Boolean = false): String!
        nickname: String!
        toys: [Toy!]!
      }

      interface Canine {
        barkVolume: Int!
      }

      interface Feline {
        meowVolume: Int!
      }

      type Dog implements Pet & Mammal & Canine {
        name(surname: Boolean = false): String!
        nickname: String!
        doesKnowCommand(dogCommand: PetCommand): Boolean!
        barkVolume: Int!
        toys: [Toy!]!
      }

      type Cat implements Pet & Mammal & Feline {
        name(surname: Boolean = false): String!
        nickname: String!
        doesKnowCommand(catCommand: PetCommand): Boolean!
        meowVolume: Int!
        toys: [Toy!]!
      }

      type Toy {
        name: String!
        size: ToySize!
        image(maxWidth: Int!): String!
      }
    |)
  }

  describe "unique fields" do
    let(:query_string) {%|
      {
        dog {
          name
          nickname
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields" do
    let(:query_string) {%|
      {
        dog {
          name
          name
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields with identical input objects" do
    let(:query_string) {%|
      mutation {
        registerPet(params: { name: "Fido", species: DOG }) {
          name
        }
        registerPet(params: { name: "Fido", species: DOG }) {
          __typename
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields with identical args" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: SIT)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields with identical values" do
    let(:query_string) {%|
      query($dogCommand: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: $dogCommand)
          doesKnowCommand(dogCommand: $dogCommand)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical aliases and fields" do
    let(:query_string) {%|
      {
        dog {
          otherName: name
          otherName: name
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "different args with different aliases" do
    let(:query_string) {%|
      {
        dog {
          knowsSit: doesKnowCommand(dogCommand: SIT)
          knowsDown: doesKnowCommand(dogCommand: DOWN)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "conflicting args value and var" do
    let(:query_string) {%|
      query ($dogCommand: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: $dogCommand)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {dogCommand:"$dogCommand"}?)], error_messages
    end
  end

  describe "multiple conflicting args value and var" do
    let(:query_string) {%|
      query ($dogCommand: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: HEEL)
          doesKnowCommand(dogCommand: $dogCommand)
        }
      }
    |}

    it "fails rule" do
      message = %Q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {dogCommand:"HEEL"} or {dogCommand:"$dogCommand"}?)

      assert_equal [message], error_messages
    end
  end

  describe "very large multiple conflicting args value and var" do
    let(:query_string) {%|
      query ($a: PetCommand, $b: PetCommand, $c: PetCommand, $d: PetCommand, $e: PetCommand, $f: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: HEEL)
          doesKnowCommand(dogCommand: JUMP)
          doesKnowCommand(dogCommand: DOWN)
          doesKnowCommand(dogCommand: $a)
          doesKnowCommand(dogCommand: $b)
          doesKnowCommand(dogCommand: $c)
          doesKnowCommand(dogCommand: $d)
          doesKnowCommand(dogCommand: $e)
          doesKnowCommand(dogCommand: $f)
        }
      }
    |}

    it "fails rule" do
      assert_equal 1, error_messages.size # instead of n**2 = 100
      assert_match %r/SIT.*HEEL.*JUMP.*DOWN.*\$a.*\$b.*\$c.*\$d.*\$e.*\$f/, error_messages.first
    end
  end

  describe "conflicting args value and var" do
    let(:query_string) {%|
      query ($varOne: PetCommand, $varTwo: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: $varOne)
          doesKnowCommand(dogCommand: $varTwo)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"$varOne"} or {dogCommand:"$varTwo"}?)], error_messages
    end
  end

  describe "different directives with different aliases" do
    let(:query_string) {%|
      {
        dog {
          nameIfTrue: name @include(if: true)
          nameIfFalse: name @include(if: false)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "different skip/include directives accepted" do
    let(:query_string) {%|
      {
        dog {
          name @include(if: true)
          name @include(if: false)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "same aliases with different field targets" do
    let(:query_string) {%|
      {
        dog {
          fido: name
          fido: nickname
        }
      }
    |}

    it "fails rule" do
      assert_equal ["Field 'fido' has a field conflict: name or nickname?"], error_messages
    end
  end

  describe "multiple aliases with different field targets" do
    let(:query_string) {%|
      {
        dog {
          fido: name
          fido: nickname
          fido: barkVolume
        }
      }
    |}

    it "fails rule" do
      assert_equal ["Field 'fido' has a field conflict: name or nickname or barkVolume?"], error_messages
    end
  end

  describe "alias masking direct field access" do
    let(:query_string) {%|
      {
        dog {
          name: nickname
          name
        }
      }
    |}

    it "fails rule" do
      assert_equal ["Field 'name' has a field conflict: nickname or name?"], error_messages
    end
  end

  describe "different args, second adds an argument" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand
          doesKnowCommand(dogCommand: HEEL)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {} or {dogCommand:"HEEL"}?)], error_messages
    end
  end

  describe "different args, second missing an argument" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {}?)], error_messages
    end
  end

  describe "conflicting args" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: HEEL)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {dogCommand:"HEEL"}?)], error_messages
    end
  end

  describe "conflicting arg values" do
    let(:query_string) {%|
      {
        toy {
          image(maxWidth: 10)
          image(maxWidth: 20)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'image' has an argument conflict: {maxWidth:"10"} or {maxWidth:"20"}?)], error_messages
    end
  end

  describe "encounters conflict in fragments" do
    let(:query_string) {%|
      {
        pet {
          ...A
          ...B
          name
        }
      }

      fragment A on Dog {
        x: name
      }

      fragment B on Dog {
        x: nickname
        name: nickname
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'name' has a field conflict: name or nickname?",
        "Field 'x' has a field conflict: name or nickname?"
      ], error_messages
    end

    describe "with error limiting" do
      describe("disabled") do
        let(:args) {
          { max_errors: nil }
        }

        it "does not limit the number of errors" do
          assert_equal [
            "Field 'name' has a field conflict: name or nickname?",
            "Field 'x' has a field conflict: name or nickname?"
          ], error_messages
        end
      end

      describe("enabled") do
        let(:args) {
          { max_errors: 1 }
        }

        it "does limit the number of errors" do
          assert_equal [
            "Field 'name' has a field conflict: name or nickname?"
          ], error_messages
        end
      end
    end
  end


  describe "deep conflict" do
    let(:query_string) {%|
      {
        dog {
          x: name
        }

        dog {
          x: nickname
        }
      }
    |}

    it "fails rule" do
      expected_errors = [
        {
          "message"=>"Field 'x' has a field conflict: name or nickname?",
          "locations"=>[
            {"line"=>4, "column"=>11},
            {"line"=>8, "column"=>11}
          ],
          "path"=>[],
          "extensions"=>{"code"=>"fieldConflict", "fieldName"=>"x", "conflicts"=>"name or nickname"}
        }
      ]
      assert_equal expected_errors, errors
    end
  end

  describe "deep conflict with multiple issues" do
    let(:query_string) {%|
      {
        dog {
          x: name
          y: barkVolume
        }

        dog {
          x: nickname
          y: doesKnowCommand
        }
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'x' has a field conflict: name or nickname?",
        "Field 'y' has a field conflict: barkVolume or doesKnowCommand?",
      ], error_messages
    end

    describe "with error limiting" do
      describe("disabled") do
        let(:args) {
          { max_errors: nil }
        }

        it "does not limit the number of errors" do
          assert_equal(error_messages, [
            "Field 'x' has a field conflict: name or nickname?",
            "Field 'y' has a field conflict: barkVolume or doesKnowCommand?",
          ])
        end
      end

      describe("enabled") do
        let(:args) {
          { max_errors: 1 }
        }

        it "does limit the number of errors" do
          assert_equal(error_messages, [
            "Field 'x' has a field conflict: name or nickname?",
          ])
        end
      end
    end
  end

  describe "very deep conflict" do
    let(:query_string) {%|
      {
        dog {
          toys {
            x: name
          }
        }

        dog {
          toys {
            x: size
          }
        }
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'x' has a field conflict: name or size?",
      ], error_messages
    end
  end


  describe "same aliases allowed on non-overlapping fields" do
    let(:query_string) {%|
      {
        pet {
          ... on Dog {
            name
          }
          ... on Cat {
            name: nickname
          }
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "nested spreads on the same type with a conflict" do
    let(:query_string) {%|
      {
        dog {
          name
          ...D
        }
      }

      fragment D on Dog {
        ...D2
      }

      fragment D2 on Dog {
        name: __typename
      }
    |}

    it "finds a conflict" do
      assert_equal [
        {"message"=>"Field 'name' has a field conflict: name or __typename?",
          "locations"=>[{"line"=>4, "column"=>11}, {"line"=>14, "column"=>9}],
          "path"=>[],
          "extensions"=>
          {"code"=>"fieldConflict",
           "fieldName"=>"name",
           "conflicts"=>"name or __typename"}
        }
      ], errors
    end
  end

  describe "same aliases not allowed on different interfaces" do
    let(:query_string) {%|
      {
        pet {
          ... on Pet {
            name
          }
          ... on Mammal {
            name: nickname
          }
        }
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'name' has a field conflict: name or nickname?",
      ], error_messages
    end
  end

  describe "same aliases on divergent abstract types" do
    let(:query_string) {%|
      {
        animal {
          ... on Feline {
            volume: meowVolume
          }
          ... on Canine {
            volume: barkVolume
          }
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "same aliases allowed on different parent interfaces and different concrete types" do
    let(:query_string) {%|
      {
        pet {
          ... on Pet {
            ...X
          }
          ... on Mammal {
            ...Y
          }
        }
      }

      fragment X on Dog {
        name
      }
      fragment Y on Cat {
        name: nickname
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "allows different args where no conflict is possible" do
    let(:query_string) {%|
      {
        pet {
          ... on Dog {
            ...X
          }
          ... on Cat {
            ...Y
          }
        }
      }

      fragment X on Pet {
        name(surname: true)
      }

      fragment Y on Pet {
        name
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end

    describe "allows different args where no conflict is possible" do
      let(:query_string) {%|
        {
          pet {
            ... on Dog {
              ... on Pet {
                name
              }
            }
            ... on Cat {
              name(surname: true)
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end

    describe "allows different args where no conflict is possible with uneven abstract scoping" do
      let(:query_string) {%|
        {
          pet {
            ... on Pet {
              ... on Dog {
                name
              }
            }
            ... on Cat {
              name(surname: true)
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end
  end

  describe "allows different args where no conflict is possible deep" do
    let(:query_string) {%|
      {
        pet {
          ... on Dog {
            ...X
          }
        }
        pet {
          ... on Cat {
            ...Y
          }
        }
      }

      fragment X on Pet {
        name(surname: true)
      }

      fragment Y on Pet {
        name
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "arguments that are a list of enums, in fragments" do
    let(:schema) {
      GraphQL::Schema.from_definition <<-GRAPHQL
      type Query {
        field(categories: [Category!]): Int
      }

      enum Category {
        A
        B
        C
      }
      GRAPHQL
    }

    describe "When there's not a conflict" do
      let(:query_string) {
        "
        {
          field(categories: [A, B, C])
          ...Q
        }
        fragment Q on Query {
          field(categories: [A, B, C])
        }
        "
      }

      it "doesn't find errors" do
        assert_equal [], errors
      end
    end

    describe "When there is a conflict" do
      let(:query_string) {
        "
        {
          field(categories: [A, B])
          ...Q
        }
        fragment Q on Query {
          field(categories: [A, B, C])
        }
        "
      }

      it "adds an error" do
        expected_error = {
          "message"=>"Field 'field' has an argument conflict: {categories:\"[A, B]\"} or {categories:\"[A, B, C]\"}?",
          "locations"=>[{"line"=>3, "column"=>11}, {"line"=>7, "column"=>11}],
          "path"=>[],
          "extensions"=> {
            "code"=>"fieldConflict",
            "fieldName"=>"field",
            "conflicts"=>"{categories:\"[A, B]\"} or {categories:\"[A, B, C]\"}"
          }
        }

        assert_equal [expected_error], errors
      end
    end
  end

  describe "return types must be unambiguous" do
    let(:schema) {
      GraphQL::Schema.from_definition(%|
        type Query {
          someBox: SomeBox
          connection: Connection
        }

        type Edge {
          id: ID
          name: String
        }

        interface SomeBox {
          deepBox: SomeBox
          unrelatedField: String
        }

        type StringBox implements SomeBox {
          scalar: String
          deepBox: StringBox
          unrelatedField: String
          listStringBox: [StringBox]
          stringBox: StringBox
          intBox: IntBox
        }

        type IntBox implements SomeBox {
          scalar: Int
          deepBox: IntBox
          unrelatedField: String
          listStringBox: [StringBox]
          stringBox: StringBox
          intBox: IntBox
        }

        interface NonNullStringBox1 {
          scalar: String!
        }

        type NonNullStringBox1Impl implements SomeBox & NonNullStringBox1 {
          scalar: String!
          unrelatedField: String
          deepBox: SomeBox
        }

        interface NonNullStringBox2 {
          scalar: String!
        }

        type NonNullStringBox2Impl implements SomeBox & NonNullStringBox2 {
          scalar: String!
          unrelatedField: String
          deepBox: SomeBox
        }

        type Connection {
          edges: [Edge]
        }
      |)
    }

    describe "compatible return shapes on different return types" do
      let(:query_string) {%|
        {
          someBox {
            ... on SomeBox {
              deepBox {
                unrelatedField
              }
            }
            ... on StringBox {
              deepBox {
                unrelatedField
              }
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end

    describe "reports correctly when a non-exclusive follows an exclusive" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              deepBox {
                ...X
              }
            }
          }
          someBox {
            ... on StringBox {
              deepBox {
                ...Y
              }
            }
          }
          memoed: someBox {
            ... on IntBox {
              deepBox {
                ...X
              }
            }
          }
          memoed: someBox {
            ... on StringBox {
              deepBox {
                ...Y
              }
            }
          }
          other: someBox {
            ...X
          }
          other: someBox {
            ...Y
          }
        }
        fragment X on SomeBox {
          scalar: deepBox { unrelatedField }
        }
        fragment Y on SomeBox {
          scalar: unrelatedField
        }
      |}

      it "fails rule" do
        assert_includes error_messages, "Field 'scalar' has a field conflict: deepBox or unrelatedField?"
      end
    end

    describe "disallows differing return types despite no overlap" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              scalar
            }
            ... on StringBox {
              scalar
            }
          }
        }
      |}

      it "fails rule" do
        schema.allow_legacy_invalid_return_type_conflicts(false)
        assert_equal ["Field 'scalar' has a return_type conflict: `Int` or `String`?"], error_messages
      end
    end

    describe "disallows differing nullability despite no overlap" do
      let(:query_string) {%|
        {
          someBox {
            ... on NonNullStringBox1 {
              scalar
            }
            ... on StringBox {
              scalar
            }
          }
        }
      |}

      it "fails rule" do
        schema.allow_legacy_invalid_return_type_conflicts(false)
        assert_equal ["Field 'scalar' has a return_type conflict: `String!` or `String`?"], error_messages
      end
    end

    describe "disallows differing return type list on object types" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              box: listStringBox {
                scalar
              }
            }
            ... on StringBox {
              box: stringBox {
                scalar
              }
            }
          }
        }
      |}

      it "fails rule" do
        schema.allow_legacy_invalid_return_type_conflicts(false)
        assert_equal ["Field 'box' has a return_type conflict: `[StringBox]` or `StringBox`?"], error_messages
      end
    end

    describe "disallows differing deep return types despite no overlap" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              box: stringBox {
                scalar
              }
            }
            ... on StringBox {
              box: intBox {
                scalar
              }
            }
          }
        }
      |}

      it "fails rule" do
        schema.allow_legacy_invalid_return_type_conflicts(false)
        assert_equal ["Field 'scalar' has a return_type conflict: `String` or `Int`?"], error_messages
      end
    end

    describe "detects alias conflict in shared subfield type across exclusive parents" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              box: stringBox {
                val: scalar
                val: unrelatedField
              }
            }
            ... on StringBox {
              box: stringBox {
                val: scalar
              }
            }
          }
        }
      |}

      it "detects the subfield conflict" do
        assert_includes error_messages, "Field 'val' has a field conflict: scalar or unrelatedField?"
      end
    end

    describe "same wrapped scalar return types on different interfaces" do
      let(:query_string) {%|
        {
          someBox {
            ... on NonNullStringBox1 {
              scalar
            }
            ... on NonNullStringBox2 {
              scalar
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end

    describe "allows non-conflicting overlapping types" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              scalar: unrelatedField
            }
            ... on StringBox {
              scalar
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end

    describe "compares deep types including list" do
      let(:query_string) {%|
        {
          connection {
            ...edgeID
            edges {
              id: name
            }
          }
        }

        fragment edgeID on Connection {
          edges {
            id
          }
        }
      |}

      it "detects the deep conflict through list type" do
        assert error_messages.any? { |m| m.include?("Field 'id' has a field conflict") && m.include?("name") }
      end
    end

    describe "conflicting return types on potentially overlapping types" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              scalar
            }
            ... on NonNullStringBox1 {
              scalar
            }
          }
        }
      |}

      it "fails rule" do
        schema.allow_legacy_invalid_return_type_conflicts(false)
        assert_equal ["Field 'scalar' has a return_type conflict: `Int` or `String!`?"], error_messages
      end
    end
  end

  describe "conflicts exceeding the max_errors count" do
    signature = (1..20).map { |n| "$arg#{n}: PetCommand" }.join(', ')
    fields = (1..20).map { |n| "doesKnowCommand(dogCommand: $arg#{n})" }.join(" ")

    let(:args) do
      { max_errors: 10 }
    end

    let(:query_string) {%|
      query (#{signature}) {
        dog { #{fields} }
      }
    |}

    it "fails rule" do
      assert_equal 1, error_messages.size
      (1..11).each do |n|
        assert_match %r/\$arg#{n}/, error_messages.first
      end

      refute_match %r/\$arg12/, error_messages.first
    end
  end

  describe "Conflicting leaf typed fields" do
    let(:schema) { GraphQL::Schema.from_definition(<<-GRAPHQL)
      interface Thing {
        name: String
      }

      type Dog implements Thing {
        spots: Boolean
      }

      type Jaguar implements Thing {
        spots: Int
      }

      type Query {
        thing: Thing
      }
      GRAPHQL
    }

    let(:query_str) { <<-GRAPHQL
        {
          thing {
            ... on Dog { spots }
            ... on Jaguar { spots }
          }
        }
      GRAPHQL
    }

    it "warns by default" do
      res = nil
      stdout, _stderr = capture_io do
        res = schema.validate(query_str)
      end
      assert_equal [], res
      expected_warning = [
        "GraphQL-Ruby encountered mismatched types in this query: `Boolean` (at 3:26) vs. `Int` (at 4:29).",
        "This will return an error in future GraphQL-Ruby versions, as per the GraphQL specification",
        "Learn about migrating here: https://graphql-ruby.org/api-doc/#{GraphQL::VERSION}/GraphQL/Schema.html#allow_legacy_invalid_return_type_conflicts-class_method"
    ].join("\n")
      assert_includes stdout, expected_warning
    end

    it "calls the handler when legacy is enabled" do
      legacy_schema = Class.new(schema) do
        allow_legacy_invalid_return_type_conflicts(true)
        def self.legacy_invalid_return_type_conflicts(query, t1, t2, node1, node2)

          raise "#{query.class} / #{t1.to_type_signature} / #{t2.to_type_signature} / #{node1.position} / #{node2.position}"
        end
      end

      err = assert_raises do
        legacy_schema.validate(query_str)
      end

      assert_equal "GraphQL::Query / Boolean / Int / [3, 26] / [4, 29]", err.message
    end

    it "adds an error when legacy is disabled" do
      future_schema = Class.new(schema) { allow_legacy_invalid_return_type_conflicts(false) }
      res = future_schema.validate(query_str)
      expected_error = {
        "message"=>"Field 'spots' has a return_type conflict: `Boolean` or `Int`?",
        "locations"=>[{"line"=>3, "column"=>26}, {"line"=>4, "column"=>29}],
        "path"=>[],
        "extensions"=>
          {"code"=>"fieldConflict",
           "fieldName"=>"spots",
           "conflicts"=>"`Boolean` or `Int`"}
        }
      assert_equal [expected_error], res.map(&:to_h)
    end

    it "inherits allow_legacy_invalid_empty_selections_on_union" do
      base_schema = Class.new(schema) { allow_legacy_invalid_return_type_conflicts(true) }
      ext_schema = Class.new(base_schema)
      assert ext_schema.allow_legacy_invalid_return_type_conflicts
    end
  end

  describe "conflicting list / non-list fields" do
    it "requires matching list/non-list structure" do
      schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query {
          u: U
        }

        union U = A | B

        type A {
          f: [Int]
        }

        type B {
          f: Int
        }
      GRAPHQL

      schema.allow_legacy_invalid_return_type_conflicts(false)

      query_str = <<~GRAPHQL
        {
          u {
            ... on A { f }
            ... on B { f }
          }
        }
      GRAPHQL

      res = schema.validate(query_str)
      assert_equal ["Field 'f' has a return_type conflict: `[Int]` or `Int`?"], res.map(&:message)

      query_str = <<~GRAPHQL
        {
          u {
            ... on B { f }
            ... on A { f }
          }
        }
      GRAPHQL

      res = schema.validate(query_str)
      assert_equal ["Field 'f' has a return_type conflict: `Int` or `[Int]`?"], res.map(&:message)
    end
  end

  describe "conflicting argument names" do
    it "detects fields with different argument names as a conflict" do
      arg_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query {
          dog: Dog
        }
        type Dog {
          isAtLocation(x: Int, y: Int): Boolean
        }
      GRAPHQL

      res = arg_schema.validate("{ dog { isAtLocation(x: 0) isAtLocation(y: 0) } }")
      assert res.any? { |e| e.message.include?("argument conflict") }
    end
  end

  describe "reports deep conflict to nearest common ancestor" do
    it "detects conflict within a sub-selection that has a non-conflicting sibling" do
      deep_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { field: T }
        type T { deepField: T x: String y: String a: String b: String }
      GRAPHQL

      query_str = <<~GRAPHQL
        {
          field {
            deepField { x: a }
            deepField { x: b }
          }
          field {
            deepField { y }
          }
        }
      GRAPHQL

      res = deep_schema.validate(query_str)
      assert res.any? { |e| e.message.include?("Field 'x' has a field conflict") }
    end
  end

  describe "reports deep conflict to nearest common ancestor in fragments" do
    it "detects conflict through fragment spreads" do
      deep_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { field: T }
        type T { deepField: T deeperField: T x: String y: String a: String b: String }
      GRAPHQL

      query_str = <<~GRAPHQL
        {
          field { ...F }
          field { ...F }
        }
        fragment F on T {
          deepField {
            deeperField { x: a }
            deeperField { x: b }
          }
          deepField {
            deeperField { y }
          }
        }
      GRAPHQL

      res = deep_schema.validate(query_str)
      assert res.any? { |e| e.message.include?("Field 'x' has a field conflict") }
    end
  end

  describe "reports deep conflict in nested fragments" do
    it "detects cross-fragment conflicts at the same nesting depth" do
      deep_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { field: T }
        type T { x: String a: String b: String }
      GRAPHQL

      # Both fragments at the same depth — avoids the preexisting uneven
      # parent length limitation in mutually_exclusive?
      query_str = <<~GRAPHQL
        {
          field { ...F }
          field { ...I }
        }
        fragment F on T { x: a }
        fragment I on T { x: b }
      GRAPHQL

      res = deep_schema.validate(query_str)
      assert res.any? { |e| e.message.include?("Field 'x' has a field conflict") }
    end

    it "detects conflicts in multi-fragment chains at same depth" do
      deep_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { field: T }
        type T { x: String y: String a: String b: String c: String d: String }
      GRAPHQL

      # F and I are both at depth 1, G and J at depth 2.
      # x: a (depth 1, from F) conflicts with x: b (depth 1, from I) — same depth.
      # y: c (depth 2, from G) conflicts with y: d (depth 2, from J) — same depth.
      # NOTE: cross-depth comparisons (e.g. F.x vs J.x at depth 1 vs 2) are a
      # known limitation — mutually_exclusive? treats uneven parent lengths as exclusive.
      query_str = <<~GRAPHQL
        {
          field { ...F ...I }
        }
        fragment F on T { x: a ...G }
        fragment G on T { y: c }
        fragment I on T { x: b ...J }
        fragment J on T { y: d }
      GRAPHQL

      res = deep_schema.validate(query_str)
      field_conflicts = res.select { |e| e.message.include?("field conflict") }
      assert field_conflicts.any? { |e| e.message.include?("'x'") }
      assert field_conflicts.any? { |e| e.message.include?("'y'") }
    end
  end

  describe "large field set with divergent sub-selections (>4 optimization)" do
    describe "all same signature, conflict in non-first field" do
      let(:query_string) {%|
        {
          pet {
            ...F1
            ...F2
            ...F3
            ...F4
            ...F5
          }
        }

        fragment F1 on Dog { toys { x: name } }
        fragment F2 on Dog { toys { x: name } }
        fragment F3 on Dog { toys { x: name } }
        fragment F4 on Dog { toys { x: size } }
        fragment F5 on Dog { toys { x: name } }
      |}

      it "detects the sub-selection conflict" do
        assert error_messages.any? { |m| m.include?("Field 'x' has a field conflict") && m.include?("name") && m.include?("size") }
      end
    end

    describe "grouped path, conflict within same-signature group" do
      let(:query_string) {%|
        {
          pet {
            ...G1
            ...G2
            ...G3
            ...G4
            ...G5
            ...G6
          }
        }

        fragment G1 on Dog { toys { x: name } }
        fragment G2 on Dog { toys { x: name } }
        fragment G3 on Dog { toys { x: name } }
        fragment G4 on Dog { toys { x: size } }
        fragment G5 on Dog { doesKnowCommand(dogCommand: SIT) }
        fragment G6 on Dog { doesKnowCommand(dogCommand: HEEL) }
      |}

      it "detects both the sub-selection and argument conflicts" do
        assert error_messages.any? { |m| m.include?("Field 'x' has a field conflict") && m.include?("name") && m.include?("size") }
        assert error_messages.any? { |m| m.include?("Field 'doesKnowCommand' has an argument conflict") }
      end
    end
  end

  describe "boundary at exactly 4 and 5 fields" do
    describe "4 fields uses O(n^2) path and catches conflict" do
      let(:query_string) {%|
        {
          dog {
            ...B1
            ...B2
            ...B3
            ...B4
          }
        }

        fragment B1 on Dog { toys { x: name } }
        fragment B2 on Dog { toys { x: name } }
        fragment B3 on Dog { toys { x: name } }
        fragment B4 on Dog { toys { x: size } }
      |}

      it "detects the conflict" do
        assert error_messages.any? { |m| m.include?("Field 'x' has a field conflict") && m.include?("name") && m.include?("size") }
      end
    end

    describe "5 fields triggers optimization and still catches conflict" do
      let(:query_string) {%|
        {
          dog {
            ...B1
            ...B2
            ...B3
            ...B4
            ...B5
          }
        }

        fragment B1 on Dog { toys { x: name } }
        fragment B2 on Dog { toys { x: name } }
        fragment B3 on Dog { toys { x: size } }
        fragment B4 on Dog { toys { x: name } }
        fragment B5 on Dog { toys { x: name } }
      |}

      it "detects the conflict" do
        assert error_messages.any? { |m| m.include?("Field 'x' has a field conflict") && m.include?("name") && m.include?("size") }
      end
    end
  end

  describe "triple-nested named fragment conflict" do
    let(:query_string) {%|
      {
        dog {
          name
          ...A
        }
      }

      fragment A on Dog {
        ...B
      }

      fragment B on Dog {
        ...C
      }

      fragment C on Dog {
        name: __typename
      }
    |}

    it "detects the conflict through three levels of fragments" do
      assert_equal ["Field 'name' has a field conflict: name or __typename?"], error_messages
    end
  end

  describe "same named fragment spread at multiple nesting levels" do
    let(:query_string) {%|
      {
        pet {
          ...F
          ... on Dog {
            ...F
          }
        }
      }

      fragment F on Pet {
        name
        name: nickname
      }
    |}

    it "detects the conflict" do
      assert_includes error_messages, "Field 'name' has a field conflict: name or nickname?"
    end
  end

  describe "inline fragment without type condition" do
    let(:query_string) {%|
      {
        dog {
          ... {
            name
            name: nickname
          }
        }
      }
    |}

    it "detects the conflict" do
      assert_equal ["Field 'name' has a field conflict: name or nickname?"], error_messages
    end

    describe "no conflict" do
      let(:query_string) {%|
        {
          dog {
            ... {
              name
              nickname
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end
  end

  describe "nested list wrapping mismatch" do
    it "detects [[Int]] vs [Int] conflict" do
      nested_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { u: U }
        union U = A | B
        type A { f: [[Int]] }
        type B { f: [Int] }
      GRAPHQL
      nested_schema.allow_legacy_invalid_return_type_conflicts(false)

      res = nested_schema.validate("{ u { ... on A { f } ... on B { f } } }")
      assert_equal ["Field 'f' has a return_type conflict: `[[Int]]` or `[Int]`?"], res.map(&:message)
    end

    it "detects [String!] vs [String] conflict" do
      null_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { u: U }
        union U = A | B
        type A { f: [String!] }
        type B { f: [String] }
      GRAPHQL
      null_schema.allow_legacy_invalid_return_type_conflicts(false)

      res = null_schema.validate("{ u { ... on A { f } ... on B { f } } }")
      assert_equal ["Field 'f' has a return_type conflict: `[String!]` or `[String]`?"], res.map(&:message)
    end
  end

  describe "on_field catches sub-selection conflict within a single field" do
    let(:query_string) {%|
      {
        dog {
          toys {
            x: name
          }
          toys {
            x: size
          }
        }
      }
    |}

    it "detects the conflict" do
      assert_equal ["Field 'x' has a field conflict: name or size?"], error_messages
    end
  end

  describe "allows different order of args" do
    it "does not conflict when arguments are in different order" do
      arg_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query {
          someField(a: String, b: String): String
        }
      GRAPHQL

      res = arg_schema.validate("{ someField(a: null, b: null) someField(b: null, a: null) }")
      assert_equal [], res
    end
  end

  describe "allows different order of input object fields in arg values" do
    let(:query_string) {%|
      mutation {
        registerPet(params: { name: "Fido", species: DOG }) { name }
        registerPet(params: { species: DOG, name: "Fido" }) { __typename }
      }
    |}

    # Known limitation: serialize_arg uses to_query_string which preserves AST
    # key order for input objects. graphql-js treats different key orders as
    # equivalent, but graphql-ruby currently does not.
    it "reports a false positive argument conflict" do
      assert error_messages.any? { |m| m.include?("argument conflict") }
    end
  end

  describe "reports each conflict once" do
    it "deduplicates conflicts across multiple spreads of same fragments" do
      dedup_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { f1: T f2: T f3: T }
        type T { x: String a: String b: String c: String }
      GRAPHQL

      query_str = <<~GRAPHQL
        {
          f1 { ...A ...B }
          f2 { ...B ...A }
          f3 { ...A ...B x: c }
        }
        fragment A on T { x: a }
        fragment B on T { x: b }
      GRAPHQL

      res = dedup_schema.validate(query_str)
      x_conflicts = res.select { |e| e.message.include?("'x'") && e.message.include?("field conflict") }
      # Should report the conflict but not exponentially many times
      assert x_conflicts.size >= 1
      assert x_conflicts.size <= 3 # at most one per selection set
    end
  end

  describe "identical fields with identical directives" do
    let(:query_string) {%|
      {
        dog {
          name @include(if: true)
          name @include(if: true)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "ignores unknown fragments" do
    let(:query_string) {%|
      {
        dog {
          name
          ...Unknown
          ...Known
        }
      }

      fragment Known on Dog {
        name
        ...OtherUnknown
      }
    |}

    it "does not crash" do
      # Unknown fragments are caught by other rules, this one should not crash
      assert_kind_of Array, errors
    end
  end

  describe "ignores unknown types in inline fragments" do
    let(:query_string) {%|
      {
        pet {
          ... on UnknownType {
            name
          }
          ... on Dog {
            name
          }
        }
      }
    |}

    it "does not crash" do
      assert_kind_of Array, errors
    end
  end

  describe "does not infinite loop on immediately recursive fragment" do
    let(:query_string) {%|
      {
        dog {
          ...fragA
        }
      }

      fragment fragA on Dog {
        name
        ...fragA
      }
    |}

    it "does not crash" do
      assert_kind_of Array, errors
    end
  end

  describe "does not infinite loop on transitively recursive fragment" do
    let(:query_string) {%|
      {
        dog {
          ...fragA
        }
      }

      fragment fragA on Dog { name ...fragB }
      fragment fragB on Dog { nickname ...fragC }
      fragment fragC on Dog { barkVolume ...fragA }
    |}

    it "does not crash" do
      assert_kind_of Array, errors
    end
  end

  describe "finds invalid case even with immediately recursive fragment" do
    let(:query_string) {%|
      {
        dog {
          ...sameAliases
        }
      }

      fragment sameAliases on Dog {
        ...sameAliases
        fido: name
        fido: nickname
      }
    |}

    it "detects the conflict" do
      assert_includes error_messages, "Field 'fido' has a field conflict: name or nickname?"
    end
  end

  describe "finds invalid case with field named after fragment" do
    it "detects alias conflict where alias matches fragment name" do
      frag_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { fragA: String a: String b: String }
      GRAPHQL

      query_str = <<~GRAPHQL
        {
          fragA
          ...fragA
        }
        fragment fragA on Query {
          fragA: b
        }
      GRAPHQL

      res = frag_schema.validate(query_str)
      assert res.any? { |e| e.message.include?("field conflict") }
    end
  end

  describe "does not infinite loop on recursive fragments separated by fields" do
    it "handles mutual recursion through intermediate fields" do
      rec_schema = GraphQL::Schema.from_definition <<~GRAPHQL
        type Query { field: T }
        type T { x: T name: String }
      GRAPHQL

      query_str = <<~GRAPHQL
        {
          field { ...fragA ...fragB }
        }
        fragment fragA on T {
          x { ...fragA ...fragB }
        }
        fragment fragB on T {
          x { ...fragA ...fragB }
        }
      GRAPHQL

      res = rec_schema.validate(query_str)
      assert_kind_of Array, res
    end
  end

  describe "duplicate aliases on a interface with inline fragment spread" do
    class DuplicateAliasesSchema < GraphQL::Schema
      module Node
        include GraphQL::Schema::Interface
        field :id, ID

        def self.resolve_type(obj, ctx)
          Repository
        end
      end

      class Repository < GraphQL::Schema::Object
        implements Node
        field :name, String
        field :id, ID
      end

      class Query < GraphQL::Schema::Object
        field :node, Node, fallback_value: { name: "graphql-ruby", id: "abcdef" }
      end

      query(Query)
      orphan_types(Repository)
    end

    it "returns an error" do
      query_str = 'query {
        node {
          ... on Repository {
            info: name
            info: id
          }
        }
      }
      '

      res = DuplicateAliasesSchema.execute(query_str)
      assert_equal ["Field 'info' has a field conflict: name or id?"], res["errors"].map { |e| e["message"] }
    end
  end
end
