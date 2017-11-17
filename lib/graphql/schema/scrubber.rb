# frozen_string_literal: true
require "set"

module GraphQL
  class Schema
    # Pass options to `use(SomeTracing, scrub_variables: { ... })`
    #
    # @api private
    class Scrubber
      # Create a scrubber which filters query variables.
      #
      # It only filters variables, not literal values in the query string.
      #
      # @param whitelist [Array<String, Symbol>] Argument names to _allow_
      # @param blacklist [Array<String, Symbol>] Argument names to _hide_
      # @param mutations [Boolean] If false, _no_ variables to mutations will be shown
      def initialize(whitelist: nil, blacklist: nil, mutations: nil)
        @whitelist = whitelist ? whitelist.map(&:to_s).to_set  : nil
        @blacklist = blacklist ? blacklist.map(&:to_s).to_set : nil
        if @whitelist && @blacklist
          raise ArgumentError, "#{self.class.name} supports whitelist: _or_ blacklist:, but not both."
        end
        @mutations = mutations
      end

      SCRUBBED = "*****"

      # @return [Hash]
      def scrubbed_variables(query)
        var_h = query.variables.to_h
        if @mutations == false && query.mutation?
          filter_value(var_h, scrub_all: true)
        elsif @whitelist || @blacklist
          filter_value(var_h, scrub_all: false)
        else
          # No filtering, but convert it to a plain hash
          filter_value(var_h, scrub_all: false)
        end
      end

      private

      def filter_value(dirty_h, scrub_all:)
        case dirty_h
        when GraphQL::Query::Arguments
          filter_value(dirty_h.to_h, scrub_all: scrub_all)
        when Hash
          clean_h = {}
          dirty_h.each do |k, v|
            # If `scrub_all`, we're hiding it.
            # Otherwise, make sure:
            # - There's no whitelist OR the key is on the whitelist; AND
            # - There's no blacklist OR the key is NOT on the blacklist
            # If one of those checks failed, then we're hiding it (whitelist/blacklist check failed)
            clean_h[k] = if scrub_all
              SCRUBBED
            elsif (@whitelist.nil? || @whitelist.include?(k)) && (@blacklist.nil? || !@blacklist.include?(k))
              filter_value(v, scrub_all: scrub_all)
            else
              SCRUBBED
            end
          end
          clean_h
        when Array
          dirty_h.map { |v| filter_value(v, scrub_all: scrub_all) }
        else
          dirty_h
        end
      end
    end
  end
end
