# frozen_string_literal: true

module GraphQL
  # See [GraphQL::Railtie](rdoc-ref:GraphQL::Railtie) for automatic Rails integration
  module Autoload
    # Register a constant named `const_name` to be loaded from `path`.
    # This is like `Kernel#autoload` but it tracks the constants so they can be eager-loaded with [eager load!](rdoc-ref:#eager_load!)
    #
    # **Parameters**
    #
    # - `const_name` (`Symbol`)
    # - `path` (`String`)
    #
    # **Returns**
    #
    # - `void`
    #
    # :call-seq:
    #   autoload(Symbol const_name, String path) -> void
    def autoload(const_name, path)
      @_eagerloaded_constants ||= []
      @_eagerloaded_constants << const_name

      super const_name, path
    end

    # Call this to load this constant's `autoload` dependents and continue calling recursively
    #
    # **Returns**
    #
    # - `void`
    #
    # :call-seq:
    #   eager_load!() -> void
    def eager_load!
      @_eager_loading = true
      if @_eagerloaded_constants
        @_eagerloaded_constants.each { |const_name| const_get(const_name) }
        @_eagerloaded_constants = nil
      end
      nil
    ensure
      @_eager_loading = false
    end

    private

    # **Returns**
    #
    # - `Boolean` — `true` if GraphQL-Ruby is currently eager-loading its constants
    #
    # :call-seq:
    #   eager_loading?() -> bool
    def eager_loading?
      @_eager_loading ||= false
    end
  end
end
