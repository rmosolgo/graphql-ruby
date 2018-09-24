# frozen_string_literal: true
module GraphQL
  module Dig
    # implemented using the old activesupport #dig instead of the ruby built-in
    # so we can use some of the magic in Schema::InputObject and Query::Arguments
    # to handle stringified/symbolized keys.
    #
    # @param args [Array<[String, Symbol>] Retrieves the value object corresponding to the each key objects repeatedly
    # @return [Object]
    def dig(*args)
      val = self[args.shift]
      if val.nil? || (args.respond_to?(:empty?) ? !!args.empty? : !args)
        val
      else
        val.dig(*args)
      end
    end
  end
end
