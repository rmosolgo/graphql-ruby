# Expose some query-specific info to field resolve functions.
# It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
class GraphQL::Query::Context
  attr_accessor :projections
  attr_reader :projection_map
  def initialize(arbitrary_hash)
    @arbitrary_hash = arbitrary_hash
    @projection_map = {}
  end

  def [](key)
    @arbitrary_hash[key]
  end

  def []=(key, value)
    @arbitrary_hash[key] = value
  end

  # Evaluate the block with `projection` as {#projections}
  def projecting(projection)
    self.projections = projection
    result = yield
    self.projections = nil
    result
  end
end
