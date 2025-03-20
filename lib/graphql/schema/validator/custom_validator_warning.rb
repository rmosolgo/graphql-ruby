# frozen_string_literal: true
module GraphQL
  class Schema
    class Validator
      class CustomValidatorWarning
        COLORS = {
          cyan: "\e[96m",
          red: "\e[91;1m",
          magenta: "\e[95m",
          green: "\e[92;1m",
          reset: "\e[0m"
        }

        def self.print(validator_name)
          new(validator_name).print
        end

        def initialize(validator_name)
          @validator_name = validator_name
        end

        def print
          message = <<~WARNING
            #{border}
            #{warning_header}

            #{validator_info}
            #{risk_warning}

            #{suggestion}

            This warning appears because your schema is using a custom validator.
            To disable this warning, set Schema#validate_timeout to a higher value.
            #{border}
          WARNING

          warn message
          warn "  #{caller(3, 1).first}"
          nil
        end

        private

        def border
          colorize("*" * 80, :cyan)
        end

        def warning_header
          colorize("⚠️  WARNING! CUSTOM VALIDATOR DETECTED ⚠️", :red)
        end

        def validator_info
          "#{colorize('Custom validator:', :cyan)} #{@validator_name}"
        end

        def risk_warning
          colorize("I/O-based validators may fail unexpectedly due to the default validate_timeout setting.", :magenta)
        end

        def suggestion
          [
            colorize("If your validator is not performing I/O, consider:", :green),
            colorize("- Adjusting validate_timeout in your schema configuration", :green)
          ].join("\n")
        end

        def colorize(text, color)
          "#{COLORS[color]}#{text}#{COLORS[:reset]}"
        end
      end
    end
  end
end
