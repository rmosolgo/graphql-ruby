# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module Rails
  class << self
    sig { returns(Rails::Application) }
    def application; end

    sig { returns(Rails::Autoloaders) }
    def autoloaders; end

    sig { returns(ActiveSupport::BacktraceCleaner) }
    def backtrace_cleaner; end

    sig { returns(ActiveSupport::Cache::Store) }
    def cache; end

    sig { returns(ActiveSupport::EnvironmentInquirer) }
    def env; end

    sig { returns(ActiveSupport::ErrorReporter) }
    def error; end

    # @version >= 8.1.0.beta1
    sig { returns(ActiveSupport::EventReporter) }
    def event; end

    # @version >= 7.1.0.rc1
    sig { returns(ActiveSupport::BroadcastLogger) }
    def logger; end

    sig { returns(Pathname) }
    def root; end

    sig { returns(String) }
    def version; end
  end
end

class Rails::Application < ::Rails::Engine
  class << self
    sig { params(block: T.proc.bind(Rails::Application).void).void }
    def configure(&block); end
  end

  sig { params(block: T.proc.bind(Rails::Application).void).void }
  def configure(&block); end

  sig { returns(T.untyped) }
  def config; end
end

class Rails::Autoloaders
  Elem = type_member(:out) { { fixed: Zeitwerk::Loader } }

  sig { params(block: T.proc.params(arg0: Elem).returns(T.untyped)).returns(T.untyped) }
  def each(&block); end

  sig { returns(Zeitwerk::Loader) }
  def main; end

  sig { returns(Zeitwerk::Loader) }
  def once; end
end

class Rails::Engine < ::Rails::Railtie
  class << self
    # @shim: delegated to the instance using `method_missing`
    sig { void }
    def load_seed; end

    # @shim: delegated to the instance using `method_missing`
    sig { returns(Pathname) }
    def root; end

    # @shim: delegated to the instance using `method_missing`
    sig { params(block: T.nilable(T.proc.bind(ActionDispatch::Routing::Mapper).void)).returns(ActionDispatch::Routing::RouteSet) }
    def routes(&block); end
  end

  sig { void }
  def load_seed; end

  sig { params(block: T.nilable(T.proc.bind(ActionDispatch::Routing::Mapper).void)).returns(ActionDispatch::Routing::RouteSet) }
  def routes(&block); end
end

class Rails::Railtie
  sig { params(block: T.proc.bind(Rails::Railtie).void).void }
  def configure(&block); end

  class << self
    sig { params(block: T.proc.bind(Rake::DSL).params(app: Rails::Application).void).void }
    def rake_tasks(&block); end
  end
end

class Rails::Railtie::Configuration
  sig { params(blk: T.proc.bind(ActiveSupport::Reloader).void).void }
  def to_prepare(&blk); end
end
