# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    # Make sure every file declares its Sorbet strictness level with a `# typed:` sigil
    class SorbetSigilCop < RuboCop::Cop::Base
      MSG = 'Add a Sorbet sigil (`# typed: true`, or `# typed: false` if it has type errors) after `# frozen_string_literal: true`.'
      VALID_SIGIL = /\A# typed: (ignore|false|true|strict|strong)\s*\z/

      def on_new_investigation
        return if processed_source.lines.any? { |line| VALID_SIGIL.match?(line) }

        add_offense(processed_source.buffer.source_range.resize(0))
      end
    end
  end
end
