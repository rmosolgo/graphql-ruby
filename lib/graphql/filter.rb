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

    def merge(only:, except:)
      if only
        merged_only = ->(m, c) { self.call(m,c) && only.call(m, c) }
      else
        merged_only = self
      end
      self.class.new(only: merged_only, except: except)
    end
  end
end
