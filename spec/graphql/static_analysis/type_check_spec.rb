require "spec_helper"

describe GraphQL::StaticAnalysis::TypeCheck do
  include StaticAnalysisHelpers

  describe "selections" do
    it "requires selections on interfaces and objects"
    it "requires selections on defined fields"
    it "doesn't allow selections on unions"
    it "doesn't allow selections on scalars"
  end

  describe "arguments" do
    it "requires defined arguments"
    it "requires valid literal inputs"
    it "checks for required arguments"
  end

  describe "variables" do
    it "requires input types"
    it "requires compatible default values"
    it "requires valid usage, even on nested spreads"
  end

  describe "directives" do
    it "requires defined directives"
    it "requires valid locations"
    it "requires defined arguments"
  end

  describe "fragments" do
    it "requires defined, composite types for fragment type conditions"
    it "requires that spreads are possible"
    it "requires that object spreads in object scope are the same type"
    it "requires that object spreads in abstract scope are members of the abstract scope"
    it "requires that abstract spreads in object scope contain the object"
    it "requires that abstract spreads in abstract scopes have some types in common"
  end

  describe "error handling" do
    it "can recover from missing type condition"
    it "can recover from missing root type"
    it "can recover from missing field"
    it "can recover from missing argument"
  end
end
