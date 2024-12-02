# frozen_string_literal: true

module GraphQL
  module Autoload
    def autoload(const_name, path)
      @_eagerloaded_constants ||= []
      @_eagerloaded_constants << const_name

      super const_name, path
    end

    def eager_load!
      @_eager_loading = true
      if @_eagerloaded_constants
        @_eagerloaded_constants.each { |const_name| const_get(const_name) }
        @_eagerloaded_constants = nil
      end
    ensure
      @_eager_loading = false
    end

    private

    def eager_loading?
      @_eager_loading ||= false
    end
  end
end
