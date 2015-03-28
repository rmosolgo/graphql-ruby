# {TestNode} provides an interface for testing your nodes. It uses the same
# infrastructure for serving fields & calls as a normal node, so it's an easy way
# to make sure your nodes are set up correctly.
#
# Usually, you get a TestNode from {Node.test}.
#
# You can test calls, fields and whole query results with {TestNode}:
# - {TestNode#[]} returns values for fields.
# - {TestNode#call} returns a new TestNode with the specified calls applied.
# - {TestNode#as_result} returns a whole result for this node (if it's a node that exposes fields, you must pass those `fields:` to {Node.test}).
#
# @example Testing fields
#   person_test_node = PersonNode.test(person)
#   assert_equal "Buster Bluth",  person_test_node["name"]
#   assert_equal 3,               person_test_node["friends { count }"]
#
#   # undefined fields raise an error:
#   assert_raises(GraphQL::FieldNotDefinedError) { person_test_node["fake_field"] }
#
# @example Testing calls & result
#   date_test_node = DateNode.test(Date.new(2012, 12, 15))
#   assert_equal 2012, date_test_node["year"]
#
#   # apply call by array:
#   one_year_later = date_test_node.call("days_later", 365)
#   assert_equal 2013, one_year_later["year"]
#
#   # chain calls, apply call by string:
#   two_years_later = one_year_later.call("days_later(200).days_later(165)")
#   assert_equal 2014, two_years_later["year"]

class GraphQL::TestNode
  attr_reader :node, :fields, :calls
  def initialize(target:, node_class:, fields:, calls:)
    @fields = fields.map { |f| GraphQL.parse(:field, f)}
    call_chain = GraphQL::TestCallChain.new(*calls)
    @node = node_class.new(target, calls: call_chain.calls, fields: @fields, query: nil)
  end

  def as_result
    node.as_result
  end

  def [](field_name)
    if fields.any?
      field = fields.find { |f| f.identifier == field_name}
    else
      field = GraphQL.parse(:field, field_name)
    end

    if field.blank?
      raise "You can't request #{field_name} because this TestNode was initialized with fields #{fields.map(&:identifier).join(", ")} "
    else
      new_node = node.value_for_field(field)
      new_node.as_result
    end
  end

  def call(*args)
    self.class.new(target: node.target, node_class: node.class, fields: self.fields.map(&:identifier), calls: args)
  end
end
