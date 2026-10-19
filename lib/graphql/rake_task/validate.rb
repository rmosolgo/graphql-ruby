# frozen_string_literal: true
# typed: false
require "digest/sha2"
require "net/http"
require "erb"

module GraphQL
  class RakeTask
    extend Rake::DSL

    # Helpers for `graphql:pro:validate`.
    # Credentials are never passed to a subprocess, so they can't leak into the process list or logs.
    module Validate
      CREDENTIALS_PATTERN = /\A[a-z0-9]{11}:[a-z0-9]{11}\z/
      DIGEST_PATTERN = /\A\h{128}\z/

      module_function

      # @return [String, nil] A normalized version string, or `nil` if `version` isn't a valid gem version
      def normalize_version(version)
        # `Gem::Version.correct?` accepts `nil` and `""`, so check those first
        if !version.is_a?(String) || version.strip.empty? || !Gem::Version.correct?(version)
          nil
        else
          # Strips surrounding whitespace, leaving only `[0-9a-zA-Z.]`
          Gem::Version.new(version).to_s
        end
      end

      # @return [String, nil] `user:pass` for gems.graphql.pro, if configured
      def credentials
        creds = if defined?(Bundler) && Bundler.respond_to?(:settings)
          Bundler.settings["gems.graphql.pro"]
        end
        if creds.nil?
          # Array form doesn't use a shell, and no secrets are in the arguments
          output = IO.popen(["bundle", "config", "get", "gems.graphql.pro", "--parseable"], err: File::NULL, &:read)
          creds = output[/[a-z0-9]{11}:[a-z0-9]{11}/]
        end
        creds = creds&.strip
        creds && creds.match?(CREDENTIALS_PATTERN) ? creds : nil
      rescue SystemCallError
        nil
      end

      # @return [String, nil] The SHA512 hex digest of the downloaded gem, or `nil` if the download failed
      def fetch_gem_digest(version, creds)
        user, pass = creds.split(":", 2)
        uri = URI("https://gems.graphql.pro/gems/graphql-pro-#{version}.gem")
        req = Net::HTTP::Get.new(uri)
        req.basic_auth(user, pass)
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
        res.is_a?(Net::HTTPSuccess) ? Digest::SHA512.hexdigest(res.body) : nil
      end

      # @return [String, nil] The published digest at `uri`, or `nil` if it couldn't be fetched
      def fetch_published_digest(uri)
        res = Net::HTTP.get_response(uri)
        return nil unless res.is_a?(Net::HTTPSuccess)
        # Remove final newline from .txt file
        digest = res.body.strip
        digest.match?(DIGEST_PATTERN) ? digest : nil
      end
    end

    desc "Get the checksum of a graphql-pro version and compare it to published versions on GitHub and graphql-ruby.org"
    task "graphql:pro:validate", [:gem_version] do |t, args|
      if args[:gem_version].nil?
        raise ArgumentError, "A specific version is required, eg `rake graphql:pro:validate[1.12.0]`"
      end
      version = Validate.normalize_version(args[:gem_version])
      if version.nil?
        raise ArgumentError, "Invalid version #{args[:gem_version].inspect}, expected a gem version like `rake graphql:pro:validate[1.12.0]`"
      end
      check = "\e[32m✓\e[0m"
      ex = "\e[31m✘\e[0m"
      puts "Validating graphql-pro v#{version}"
      puts "  - Checking for graphql-pro credentials..."

      creds = Validate.credentials
      if creds.nil?
        puts "    #{ex} failed, please set with `bundle config gems.graphql.pro $MY_CREDENTIALS`"
        exit(1)
      else
        puts "    #{check} found"
      end

      puts "  - Fetching the gem..."
      gem_digest = Validate.fetch_gem_digest(version, creds)
      if gem_digest.nil?
        puts "    #{ex} failed to fetch v#{version}"
        exit(1)
      else
        puts "    #{check} fetched"
      end

      puts "  - Validating digest..."
      github_digest = Validate.fetch_published_digest(URI("https://raw.githubusercontent.com/rmosolgo/graphql-ruby/master/guides/pro/checksums/graphql-pro-#{version}.txt"))
      docs_digest = Validate.fetch_published_digest(URI("https://graphql-ruby.org/pro/checksums/graphql-pro-#{version}.txt"))

      if docs_digest == gem_digest && github_digest == gem_digest
        puts "    #{check} validated from GitHub"
        puts "    #{check} validated from graphql-ruby.org"
      else
        puts "    #{ex} SHA mismatch:"
        puts "      Downloaded:       #{gem_digest}"
        puts "      GitHub:           #{github_digest || "(not found)"}"
        puts "      graphql-ruby.org: #{docs_digest || "(not found)"}"
        puts ""
        puts "      This download of graphql-pro is invalid, please open an issue:"
        puts "      https://github.com/rmosolgo/graphql-ruby/issues/new?title=#{ERB::Util.url_encode("graphql-pro digest mismatch (#{version})")}"
        exit(1)
      end

      puts "\e[32m✔\e[0m graphql-pro #{version} validated successfully!"
    end
  end
end
