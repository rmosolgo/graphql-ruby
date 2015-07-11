class GraphQL::Directive < GraphQL::ObjectType
  LOCATIONS = [
    ON_OPERATION =  :on_operation?,
    ON_FRAGMENT =   :on_fragment?,
    ON_FIELD =      :on_field?,
  ]
  LOCATIONS.each do |location|
    define_method(location) { self.on.include?(location) }
  end

  attr_definable :on, :arguments

  def initialize(&block)
    @arguments = {}
    @on = []
    yield(self) if block_given?
  end

  def resolve(proc_or_arguments, proc=nil)
    if proc.nil?
      @resolve_proc = proc_or_arguments
    else
      @resolve_proc.call(proc_or_arguments, proc)
    end
  end

  def arguments(new_arguments=nil)
    if new_arguments.nil?
      @arguments
    else
      @arguments = new_arguments
        .reduce({}) {|memo, (k, v)| memo[k.to_s] = v; memo}
        .each { |k, v| v.respond_to?("name=") && v.name = k}
    end
  end
end
