# frozen_string_literal: true
require "strscan"

module GraphQL
  class LanguageServer
    # The client requests code completion.
    # Call out to the provider and send the response to the client.
    class ServeTextDocumentCompletion < Response
        def response
          uri = request[:params][:textDocument][:uri]
          # Add one to match GraphQL-Ruby's parser
          cursor_line = request[:params][:position][:line] + 1
          cursor_col = request[:params][:position][:character]

          logger.debug("lookup: #{cursor_line}:#{cursor_col} of #{uri}")
          content = server.cache_content(uri)

          if !content
            logger.debug("No content for URI")
            return []
          end

          if !is_graphql_code?(uri, content, cursor_line, cursor_col)
            logger.debug("Outside graphql region")
            return []
          end


          provider = CompletionProvider.new(
            text: content,
            line: cursor_line,
            column: cursor_col,
            server: server,
            logger: logger,
          )
          items = provider.response
          # Convert to LSP objects
          items.map do |item|
            LSP::Interface::CompletionItem.new(
              label: item.label,
              detail: item.detail,
              insert_text: item.insert_text,
              documentation: item.documentation,
              kind: item.kind,
            )
          end
        end

        private

        def is_graphql_code?(filename, text, line, col)
          if filename.end_with?(".graphql")
            true
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
                  return true
                end
                scan_line += 1
              else
                scanner.scan(/./)
              end
            end
            false
          elsif filename.end_with?(".erb")
            # figure out if `line` is inside `<%graphql ... %>`
            scanner = StringScanner.new(text)
            scan_line = 1
            graphql_begin = nil
            while !scanner.eos?
              if scanner.scan(/^<%graphql$/)
                logger.debug("Enter GraphQL @ #{scan_line}")
                graphql_begin = scan_line
              elsif scanner.scan(/%>/)
                logger.debug("Exit GraphQL @ #{scan_line}")
                graphql_begin = nil
              elsif scanner.scan_until(/\n/)
                if scan_line >= line && graphql_begin && graphql_begin <= line
                  logger.debug("Confirm GraphQL @ #{scan_line} (#{graphql_begin} <= #{line})")
                  return true
                end
                logger.debug("Line: #{scanner.pre_match} (#{scan_line})")
                scan_line += 1
              else
                scanner.scan(/./)
              end
            end
            false
          else
            false
          end
        end
      end
  end
end
