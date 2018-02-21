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
      }

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

      interface Pet {
        name(surname: Boolean = false): String!
        nickname: String
        toys: [Toy!]!
      }

      type Dog implements Pet {
        name(surname: Boolean = false): String!
        nickname: String
        doesKnowCommand(dogCommand: PetCommand): Boolean!
        barkVolume: Int!
        toys: [Toy!]!
      }

      type Cat implements Pet {
        name(surname: Boolean = false): String!
        nickname: String
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
      assert_equal ["Field 'name' has a field conflict: name or nickname?"], error_messages
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
        "Field 'x' has a field conflict: name or nickname?",
      ], error_messages
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
          "fields"=>[]
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
          scalar: deepBox { unreleatedField }
        }
        fragment Y on SomeBox {
          scalar: unrelatedField
        }
      |}

      it "fails rule" do
        assert_includes error_messages, "Field 'scalar' has a field conflict: deepBox or unrelatedField?"
      end
    end
  end
end
