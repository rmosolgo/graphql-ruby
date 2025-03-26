# frozen_string_literal: true
Rails.application.configure do
  gem_path = File.expand_path("../../../../../lib/graphql", __FILE__)
  gem_loader = Zeitwerk::Registry.loader_for_gem(gem_path, namespace: GraphQL, warn_on_extra_files: false)
  gem_loader.enable_reloading
  gem_loader.setup

  # Create a file watcher that will reload the gem classes when a file changes
  files = Dir.glob(File.join(gem_path, '**/*'))
  file_watcher = ActiveSupport::FileUpdateChecker.new(files) do
    gem_loader.reload
  end

  # Plug it to Rails to be executed on each request
  Rails.application.reloaders << Class.new do
    def initialize(file_watcher)
      @file_watcher = file_watcher
    end

    def updated?
      @file_watcher.execute_if_updated
    end
  end.new(file_watcher)

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log


  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
