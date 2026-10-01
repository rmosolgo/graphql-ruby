# frozen_string_literal: true
module GraphQL
  module Dig
    # implemented using the old activesupport #dig instead of the ruby built-in
    # so we can use some of the magic in Schema::InputObject and Interpreter::Arguments
    # to handle stringified/symbolized keys.
    #
    # **Parameters**
    #
    # - `own_key` (`String, Symbol`) — A key to retrieve
    # - `rest_keys` (`Array<[String, Symbol]>`) — Keys to use for retrieving nested values
    #
    # **Returns**
    #
    # - `Object`
    #
    # :call-seq:
    #   dig(String | Symbol own_key, Array[[String, Symbol]] *rest_keys) -> Object
    def dig(own_key, *rest_keys)
      val = self[own_key]
      if val.nil? || rest_keys.empty?
        val
      else
        val.dig(*rest_keys)
      end
    end
  end
end
