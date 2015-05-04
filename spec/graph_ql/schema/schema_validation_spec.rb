require 'spec_helper'

describe GraphQL::Schema::SchemaValidation do
  let(:schema) { GraphQL::SCHEMA }

  it 'runs' do
    schema.validate
  end

  describe "when the exposes_class doesnt exist" do
    before do
      Nodes::PostNode.exposes("BogusPost")
    end
    after do
      Nodes::PostNode.exposes("Post")
    end

    it 'raises an error' do
      assert_raises(GraphQL::ExposesClassMissingError) { schema.validate }
    end
  end

  describe "when there's a bad field type" do
    before do
      Nodes::PostNode.field.bogus_kind(:bogus_title, "Nonsense")
    end
    after do
      Nodes::PostNode.remove_field(:bogus_title)
    end

    it 'raises an error' do
      assert_raises(GraphQL::NodeNotDefinedError) { schema.validate }
    end
  end

  describe "when a field cant find a corresponding method" do
    before do
      Nodes::PostNode.field.string(:bogus_title, "Nonsense")
    end
    after do
      Nodes::PostNode.remove_field(:bogus_title)
    end

    it 'raises an error' do
      assert_raises(GraphQL::FieldNotImplementedError) { schema.validate }
    end
  end

  describe 'when a description is missing' do
    before do
      @prev_desc = Nodes::PostNode.description
      Nodes::PostNode.desc(nil)
    end
    after do
      Nodes::PostNode.desc(@prev_desc)
    end

    it 'raises an error' do
      assert_raises(RuntimeError) { schema.validate }
    end
  end
end