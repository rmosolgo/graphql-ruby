# frozen_string_literal: true
module GraphQL
  # @api private
  class Filter
    def initialize(only: nil, except: nil)
      @only = only
      @except = except
    end

    # Returns true if `member, ctx` passes this filter
    def call(member, ctx)
      (@only ? @only.call(member, ctx) : true) &&
      (@except ? !@except.call(member, ctx) : true)
    end

    def merge(only: nil, except: nil)
      onlies = [self].concat(Array(only))
      merged_only = MergedOnly.build(onlies)
      merged_except = MergedExcept.build(Array(except))
      self.class.new(only: merged_only, except: merged_except)
    end

    private

    class MergedOnly
      def initialize(first, second)
        @first = first
        @second = second
      end

      def call(member, ctx)
        @first.call(member, ctx) && @second.call(member, ctx)
      end

      def self.build(onlies)
        case onlies.size
        when 0
          nil
        when 1
          onlies[0]
        else
          onlies.reduce { |memo, only| self.new(memo, only) }
        end
      end
    end

    class MergedExcept < MergedOnly
      def call(member, ctx)
        @first.call(member, ctx) || @second.call(member, ctx)
      end
    end
  end
end
