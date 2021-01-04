# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::RelayClassicMutation do
  describe ".input_object_class" do
    it "is inherited, with a default" do
      custom_input = Class.new(GraphQL::Schema::InputObject)
      mutation_base_class = Class.new(GraphQL::Schema::RelayClassicMutation) do
        input_object_class(custom_input)
      end
      mutation_subclass = Class.new(mutation_base_class)

      assert_equal GraphQL::Schema::InputObject, GraphQL::Schema::RelayClassicMutation.input_object_class
      assert_equal custom_input, mutation_base_class.input_object_class
      assert_equal custom_input, mutation_subclass.input_object_class
    end
  end

  describe ".input_type" do
    it "has a reference to the mutation" do
      mutation = Class.new(GraphQL::Schema::RelayClassicMutation) do
        graphql_name "Test"
      end
      assert_equal mutation, mutation.input_type.mutation
      assert_equal mutation, mutation.input_type.graphql_definition.mutation
    end
  end

  describe ".null" do
    it "is inherited as true" do
      mutation = Class.new(GraphQL::Schema::RelayClassicMutation) do
        graphql_name "Test"
      end

      assert mutation.null
    end
  end

  describe "input argument" do
    it "sets a description for the input argument" do
      mutation = Class.new(GraphQL::Schema::RelayClassicMutation) do
        graphql_name "SomeMutation"
      end

      assert_equal "Parameters for SomeMutation", mutation.field_options[:arguments][:input][:description]
    end
  end

  describe "execution" do
    after do
      Jazz::Models.reset
    end

    it "works with no arguments" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        addSitar(input: {}) {
          instrument {
            name
          }
        }
      }
      GRAPHQL

      assert_equal "Sitar", res["data"]["addSitar"]["instrument"]["name"]
    end

    it "works with InputObject arguments" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        addEnsembleRelay(input: { ensemble: { name: "Miles Davis Quartet" } }) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      assert_equal "Miles Davis Quartet", res["data"]["addEnsembleRelay"]["ensemble"]["name"]
    end

    it "supports extras" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasExtras(input: {}) {
          nodeClass
          int
        }
      }
      GRAPHQL

      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["hasExtras"]["nodeClass"]
      assert_nil res["data"]["hasExtras"]["int"]

      # Also test with given args
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasExtras(input: {int: 5}) {
          nodeClass
          int
        }
      }
      GRAPHQL
      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["hasExtras"]["nodeClass"]
      assert_equal 5, res["data"]["hasExtras"]["int"]
    end

    it "supports field extras" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasFieldExtras(input: {}) {
          lookaheadClass
          int
        }
      }
      GRAPHQL

      assert_equal "GraphQL::Execution::Lookahead", res["data"]["hasFieldExtras"]["lookaheadClass"]
      assert_nil res["data"]["hasFieldExtras"]["int"]

      # Also test with given args
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasFieldExtras(input: {int: 5}) {
          lookaheadClass
          int
        }
      }
      GRAPHQL
      assert_equal "GraphQL::Execution::Lookahead", res["data"]["hasFieldExtras"]["lookaheadClass"]
      assert_equal 5, res["data"]["hasFieldExtras"]["int"]
    end

    it "can strip out extras" do
      ctx = {}
      res = Jazz::Schema.execute <<-GRAPHQL, context: ctx
      mutation {
        hasExtrasStripped(input: {}) {
          int
        }
      }
      GRAPHQL
      assert_equal true, ctx[:has_lookahead]
      assert_equal 51, res["data"]["hasExtrasStripped"]["int"]
    end
  end

  describe "loading multiple application objects" do
    let(:query_str) {
      <<-GRAPHQL
        mutation($ids: [ID!]!) {
          upvoteEnsembles(input: {ensembleIds: $ids}) {
            ensembles {
              id
            }
          }
        }
      GRAPHQL
    }

    it "loads arguments as objects of the given type and strips `_ids` suffix off argument name and appends `s`" do
      res = Jazz::Schema.execute(query_str, variables: { ids: ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"]})
      assert_equal ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"], res["data"]["upvoteEnsembles"]["ensembles"].map { |e| e["id"] }
    end

    it "uses the `as:` name when loading" do
      as_bands_query_str = query_str.sub("upvoteEnsembles", "upvoteEnsemblesAsBands")
      res = Jazz::Schema.execute(as_bands_query_str, variables: { ids: ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"]})
      assert_equal ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"], res["data"]["upvoteEnsemblesAsBands"]["ensembles"].map { |e| e["id"] }
    end

    it "doesn't append `s` to argument names that already end in `s`" do
      query = <<-GRAPHQL
        mutation($ids: [ID!]!) {
          upvoteEnsemblesIds(input: {ensemblesIds: $ids}) {
            ensembles {
              id
            }
          }
        }
      GRAPHQL

      res = Jazz::Schema.execute(query, variables: { ids: ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"]})
      assert_equal ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"], res["data"]["upvoteEnsemblesIds"]["ensembles"].map { |e| e["id"] }
    end

    it "returns an error instead when the ID resolves to nil" do
      res = Jazz::Schema.execute(query_str, variables: {
        ids: ["Ensemble/Nonexistant Name"],
      })
      assert_nil res["data"].fetch("upvoteEnsembles")
      assert_equal ['No object found for `ensembleIds: "Ensemble/Nonexistant Name"`'], res["errors"].map { |e| e["message"] }
    end

    it "returns an error instead when the ID resolves to an object of the wrong type" do
      res = Jazz::Schema.execute(query_str, variables: {
        ids: ["Instrument/Organ"],
      })
      assert_nil res["data"].fetch("upvoteEnsembles")
      assert_equal ["No object found for `ensembleIds: \"Instrument/Organ\"`"], res["errors"].map { |e| e["message"] }
    end

    it "raises an authorization error when the type's auth fails" do
      res = Jazz::Schema.execute(query_str, variables: {
        ids: ["Ensemble/Spinal Tap"],
      })
      assert_nil res["data"].fetch("upvoteEnsembles")
      # Failed silently
      refute res.key?("errors")
    end
  end

  describe "loading application objects" do
    let(:query_str) {
      <<-GRAPHQL
        mutation($id: ID!, $newName: String!) {
          renameEnsemble(input: {ensembleId: $id, newName: $newName}) {
            __typename
            ensemble {
              __typename
              name
            }
          }
        }
      GRAPHQL
    }

    it "loads arguments as objects of the given type" do
      res = Jazz::Schema.execute(query_str, variables: { id: "Ensemble/Robert Glasper Experiment", newName: "August Greene"})
      assert_equal "August Greene", res["data"]["renameEnsemble"]["ensemble"]["name"]
    end

    it "loads arguments as objects when provided an interface type" do
      query = <<-GRAPHQL
        mutation($id: ID!, $newName: String!) {
          renameNamedEntity(input: {namedEntityId: $id, newName: $newName}) {
            namedEntity {
              __typename
              name
            }
          }
        }
      GRAPHQL

      res = Jazz::Schema.execute(query, variables: { id: "Ensemble/Robert Glasper Experiment", newName: "August Greene"})
      assert_equal "August Greene", res["data"]["renameNamedEntity"]["namedEntity"]["name"]
      assert_equal "Ensemble", res["data"]["renameNamedEntity"]["namedEntity"]["__typename"]
    end

    it "loads arguments as objects when provided an union type" do
      query = <<-GRAPHQL
        mutation($id: ID!, $newName: String!) {
          renamePerformingAct(input: {performingActId: $id, newName: $newName}) {
            performingAct {
              __typename
              ... on Ensemble {
                name
              }
            }
          }
        }
      GRAPHQL

      res = Jazz::Schema.execute(query, variables: { id: "Ensemble/Robert Glasper Experiment", newName: "August Greene"})
      assert_equal "August Greene", res["data"]["renamePerformingAct"]["performingAct"]["name"]
      assert_equal "Ensemble", res["data"]["renamePerformingAct"]["performingAct"]["__typename"]
    end

    it "uses the `as:` name when loading" do
      band_query_str = query_str.sub("renameEnsemble", "renameEnsembleAsBand")
      res = Jazz::Schema.execute(band_query_str, variables: { id: "Ensemble/Robert Glasper Experiment", newName: "August Greene"})
      assert_equal "August Greene", res["data"]["renameEnsembleAsBand"]["ensemble"]["name"]
    end

    it "returns an error instead when the ID resolves to nil" do
      res = Jazz::Schema.execute(query_str, variables: {
        id: "Ensemble/Nonexistant Name",
        newName: "August Greene"
      })
      assert_nil res["data"].fetch("renameEnsemble")
      assert_equal ['No object found for `ensembleId: "Ensemble/Nonexistant Name"`'], res["errors"].map { |e| e["message"] }
    end

    it "returns an error instead when the ID resolves to an object of the wrong type" do
      res = Jazz::Schema.execute(query_str, variables: {
        id: "Instrument/Organ",
        newName: "August Greene"
      })
      assert_nil res["data"].fetch("renameEnsemble")
      assert_equal ["No object found for `ensembleId: \"Instrument/Organ\"`"], res["errors"].map { |e| e["message"] }
    end

    it "raises an authorization error when the type's auth fails" do
      res = Jazz::Schema.execute(query_str, variables: {
        id: "Ensemble/Spinal Tap",
        newName: "August Greene"
      })
      assert_nil res["data"].fetch("renameEnsemble")
      # Failed silently
      refute res.key?("errors")
    end
  end
end
