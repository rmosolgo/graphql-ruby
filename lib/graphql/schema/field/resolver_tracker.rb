# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class ResolverTracker
        def initialize
          @counts_by_field = Hash.new do |h, k|
            h[k] = Hash.new do |h2, k2|
              h2[k2] = 0
            end
          end
        end

        def track(field, strategy)
          @counts_by_field[field.path][strategy] += 1
        end
      end
    end
  end
end
