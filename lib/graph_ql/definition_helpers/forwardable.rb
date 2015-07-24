# Get `delegate` like Rails has
module GraphQL::Forwardable
  def delegate(*methods, to:)
    methods.each do |method_name|
      define_method(method_name) do |*args|
        self.public_send(to).public_send(method_name, *args)
      end
    end
  end
end
