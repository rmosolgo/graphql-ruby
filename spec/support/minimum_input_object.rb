# This is the minimum required interface for an input object
class MinimumInputObject
  KEY_VALUE_PAIRS = [["source", "COW"], ["fatContent", 0.4]]

  def all?
    KEY_VALUE_PAIRS.all? { |pair| yield(pair) }
  end

  def [](key)
    pair = KEY_VALUE_PAIRS.find { |k, v| k == key }
    pair[1]
  end
end
