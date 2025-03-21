# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      module CustomValidatorWarning
        def self.warn_for(validator_name)
          border = "*" * 30
          timestamp = "[#{Time.now.strftime('%Y-%m-%dT%H:%M:%S.%6N')} ##{Process.pid}]"
          warn <<~WARN
            #{border}
            WARNING: GraphQL Custom validator detected: #{validator_name}
            Custom validators with I/O operations may fail unexpectedly due to GraphQL's default validate_timeout setting. Long-running I/O operations may not be killed halfway through, resulting in unpredictable behavior. See https://graphql-ruby.org/queries/timeout.html#validation-and-analysis for more information.
            #{caller(3,1).first}
            #{timestamp}
            #{border}
          WARN
        end
      end
    end
  end
end
