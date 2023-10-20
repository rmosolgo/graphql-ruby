# frozen_string_literal: true
module GraphQL
  class Railtie < Rails::Railtie
    config.before_configuration do
      # Bootsnap compile cache has similar expiration properties,
      # so we assume that if the user has bootsnap setup it's ok
      # to piggy back on it.
      if ::Object.const_defined?("Bootsnap::CompileCache::ISeq") && Bootsnap::CompileCache::ISeq.cache_dir
        Language::Parser.cache ||= Language::Cache.new(Pathname.new(Bootsnap::CompileCache::ISeq.cache_dir).join('graphql'))
      end
    end
  end
end
