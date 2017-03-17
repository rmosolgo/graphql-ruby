# frozen_string_literal: true
module GraphQL
  class Schema
    # Tools for working with schema masks (`only` / `except`).
    #
    # In general, these are functions which, when they return `true`,
    # the `member` is hidden for the current query.
    #
    # @api private
    module Mask
      module_function

      # Combine a schema's default_mask with query-level masks.
      def combine(default_mask, except:, only:)
        query_mask = if except
          except
        elsif only
          InvertedMask.new(only)
        end

        if query_mask && (default_mask != GraphQL::Schema::NullMask)
          EitherMask.new(default_mask, query_mask)
        else
          query_mask || default_mask
        end
      end

      # @api private
      # Returns true when the inner mask returned false
      # Returns false when the inner mask returned true
      class InvertedMask
        def initialize(inner_mask)
          @inner_mask = inner_mask
        end

        def call(member, ctx)
          !@inner_mask.call(member, ctx)
        end
      end

      # Hides `member` if _either_ mask would hide the member.
      # @api private
      class EitherMask
        def initialize(first_mask, second_mask)
          @first_mask = first_mask
          @second_mask = second_mask
        end

        def call(member, ctx)
          @first_mask.call(member, ctx) || @second_mask.call(member, ctx)
        end
      end
    end
  end
end
