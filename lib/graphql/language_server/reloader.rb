# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # This helper watches for any additions, removals or edits to `globs`,
    # and returns true if anything changed.
    # TODO:
    # - Support watching `schema.json`?
    # - Support watching `graphql-reload.txt`?
    class Reloader
      def initialize(globs:, logger:)
        @globs = globs
        @logger = logger
        @reload_mtimes = {}
      end

      # Returns true if anything was reloaded
      def reload
        reloaded = []
        @globs.each do |file_glob|
          matches = Dir.glob(file_glob)
          @logger.info("Try reloading: #{matches}")
          matches.each do |filename|
            prev_mtime = @reload_mtimes[filename]
            new_mtime = File.mtime(filename)
            if new_mtime != prev_mtime
              @reload_mtimes[filename] = new_mtime
              begin
                @logger.debug("Reloading #{filename}")
                load(filename)
              rescue
                @logger.error("LOAD ERROR: #{$!.message}")
                @logger.error($!.backtrace.join("\n"))
              end

              reloaded << filename
            end
          end
        end

        reloaded.any?
      end
    end
  end
end
