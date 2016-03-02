# This is the minimum required interface for an input object
class MinimumInputObject
  include Enumerable

  KEY_VALUE_PAIRS = [["source", "COW"], ["fatContent", 0.4]]

  def each(&block)
    KEY_VALUE_PAIRS.each(&block)
  end

  def [](key)
    pair = KEY_VALUE_PAIRS.find { |k, v| k == key }
    pair[1]
  end
end

class MinimumInvalidInputObject
  include Enumerable

  KEY_VALUE_PAIRS = [["source", "KOALA"], ["fatContent", 0.4]]

  def each(&block)
    KEY_VALUE_PAIRS.each(&block)
  end

  def [](key)
    pair = KEY_VALUE_PAIRS.find { |k, v| k == key }
    pair[1]
  end
end
