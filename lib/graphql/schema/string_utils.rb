# frozen_string_literal: true
module GraphQL
  class Schema
    module StringUtils
      class << self
        # Allows to override string utility functions: camelize, constantize, underscore.
        # @param implementation - should be a module with one or multiple functions defined
        # @param block - a block with one or multiple method definitions
        #
        # Example:
        #   GraphQL::Schema::StringUtils.setup(MyModule)
        #   or
        #   GraphQL::Schema::StringUtils.setup do
        #     def camelize(string)
        #       ::ActiveSupport::Inflector.camelize(string, false)
        #     end
        #   end
        #
        def setup(implementation=nil, &block)
          singleton_class.prepend(implementation || Module.new(&block))
        end

        def camelize(string)
          return string unless string.include?("_")
          camelized = string.split('_').map(&:capitalize).join
          camelized[0] = camelized[0].downcase
          if (match_data = string.match(/\A(_+)/))
            camelized = "#{match_data[0]}#{camelized}"
          end
          camelized
        end

        # Resolves constant from string (based on Rails `ActiveSupport::Inflector.constantize`)
        def constantize(string)
          names = string.split('::')

          # Trigger a built-in NameError exception including the ill-formed constant in the message.
          Object.const_get(string) if names.empty?

          # Remove the first blank element in case of '::ClassName' notation.
          names.shift if names.size > 1 && names.first.empty?

          names.inject(Object) do |constant, name|
            if constant == Object
              constant.const_get(name)
            else
              candidate = constant.const_get(name)
              next candidate if constant.const_defined?(name, false)
              next candidate unless Object.const_defined?(name)

              # Go down the ancestors to check if it is owned directly. The check
              # stops when we reach Object or the end of ancestors tree.
              constant = constant.ancestors.inject do |const, ancestor|
                break const    if ancestor == Object
                break ancestor if ancestor.const_defined?(name, false)
                const
              end

              # Owner is in Object, so raise.
              constant.const_get(name, false)
            end
          end
        end

        def underscore(string)
          if string.match?(/\A[a-z_]+\Z/)
            return string
          end
          string2 = string.dup

          string2.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2') # URLDecoder -> URL_Decoder
          string2.gsub!(/([a-z\d])([A-Z])/,'\1_\2')     # someThing -> some_Thing
          string2.downcase!

          string2
        end
      end
    end
  end
end
