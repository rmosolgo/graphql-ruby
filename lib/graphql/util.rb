module GraphQL::Util
  module_function

  # Based on ActiveSupport's String#underscore but less aggressive and monkey-patchy
  def underscore_string(string)
    string.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      downcase
  end
end
