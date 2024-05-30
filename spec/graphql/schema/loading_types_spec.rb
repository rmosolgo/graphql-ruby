# frozen_string_literal: true
require "spec_helper"

describe "Schema loading types as needed" do
  def unload_and_reload_types(schema)
    before_types = schema.types.dup
    before_references_to = schema.references_to.dup
    before_possible_types = schema.possible_types.dup

    schema.unload_types
    schema.eager_load_types

    assert_equal before_types.size, schema.types.size
    assert_equal before_types, schema.types, "It has equivalent types"

    assert_equal before_possible_types.keys.sort, schema.possible_types.keys.sort, "It has the same possible_types keys"
    after_possible_types = schema.possible_types
    before_possible_types.each do |pt_key, before_pt|
      assert_equal before_pt.sort_by(&:graphql_name), after_possible_types[pt_key].sort_by(&:graphql_name), "It has the same possible types for #{pt_key.inspect}"
    end

    assert_equal before_references_to.keys.sort_by(&:graphql_name), schema.references_to.keys.sort_by(&:graphql_name)
    after_references = schema.references_to
    before_references_to.each do |ref_key, references|
      after_refs = after_references[ref_key].map(&:path).sort
      before_refs = references.map(&:path).sort
      assert_equal before_refs, after_refs, "It has the same references for #{ref_key} (before: #{references.size}, after: #{after_refs.size})"
    end
  end
  it "can unload and reload types" do
    pp [:before, Jazz::Query.get_field("inspectInput").all_argument_definitions]
    unload_and_reload_types(Dummy::Schema)
    unload_and_reload_types(Jazz::Schema)
  end
end
