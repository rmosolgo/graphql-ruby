# This is the minimum required interface for an input object
class MinimumInputObject
  include Enumerable

  def initialize(values)
    @values = values
  end

  def each(&block)
    @values.each(&block)
  end

  def [](key)
    @values[key]
  end
end
