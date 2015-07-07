class GraphQL::Type
  extend GraphQL::Definable
  attr_definable :type_name, :description, :interfaces

  class << self
    attr_accessor :fields
    def fields=(new_fields)
      stringified_fields = new_fields
        .reduce({}) { |memo, (key, value)| memo[key.to_s] = value; memo }
      @fields = stringified_fields
    end

    def field(type=nil)
      if type.nil?
        @access_field_definer ||= GraphQL::AccessFieldDefiner.new
      else
        # GraphQL::FieldDefiner.new(type: type)
      end
    end
  end
end
