# frozen_string_literal: true
require "strscan"
module GraphQL
  class LanguageServer
    class Cursor
      # Given a cursor in a file, determine whether it's pointing to
      # GraphQL code or not.
      #
      # Also, see if we can glean any other information from the file context.
      # @api private
      class LanguageScope
        def initialize(filename:, text:, line:, column:, logger:)
          @graphql_code = false # Maybe set `true` below
          if filename.end_with?(".graphql")
            @graphql_code = true
          elsif filename.end_with?(".rb")
            # figure out if `line` is inside `<<[-~]'?GRAPHQL'?` ... `GRAPHQL`
            scanner = StringScanner.new(text)
            scan_line = 1
            graphql_begin = nil
            while !scanner.eos?
              if scanner.scan(/^.*<<[-~]'?GRAPHQL'?.*$/)
                graphql_begin = scan_line
              elsif scanner.scan(/^\s*GRAPHQL$/)
                graphql_begin = nil
              elsif scanner.scan_until(/\n/)
                if scan_line >= line && graphql_begin && graphql_begin <= line
                  @graphql_code = true
                end
                scan_line += 1
              else
                scanner.scan(/./)
              end
            end
          elsif filename.end_with?(".erb")
            # figure out if `line` is inside `<%graphql ... %>`
            scanner = StringScanner.new(text)
            scan_line = 1
            graphql_begin = nil
            while !scanner.eos?
              if scanner.scan(/<%graphql/)
                # logger.debug("Enter GraphQL @ #{scan_line}")
                graphql_begin = scan_line
              elsif scanner.scan(/%>/)
                # logger.debug("Exit GraphQL @ #{scan_line}")
                graphql_begin = nil
              elsif scanner.scan(/\n/)
                if scan_line >= line && graphql_begin && graphql_begin <= line
                  # logger.debug("Confirm GraphQL @ #{scan_line} (#{graphql_begin} <= #{line})")
                  @graphql_code = true
                end
                # logger.debug("Line #{scan_line}: #{scanner.pre_match}")
                scan_line += 1
              else
                scanner.scan(/./)
              end
            end
          else
            logger.info("LanguageScope skipped: #{filename}")
          end
        end

        def graphql_code?
          @graphql_code
        end
      end
    end
  end
end
