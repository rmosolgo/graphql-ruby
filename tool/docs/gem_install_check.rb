# frozen_string_literal: true

require "fileutils"
require "open3"
require "rubygems/package"
require "tmpdir"

root = File.expand_path("../..", __dir__)
spec = Gem::Specification.load(File.join(root, "graphql.gemspec"))
raise "Unable to load graphql.gemspec" unless spec

Dir.mktmpdir("graphql-ruby-gem-install") do |directory|
  gem_path = Gem::Package.build(spec, true)
  install_root = File.join(directory, "gems")
  output, error, status = Open3.capture3(
    "gem", "install", gem_path,
    "--install-dir", install_root,
    "--document=rdoc,ri",
    "--ignore-dependencies",
    "--no-wrappers",
    "--no-format-executable",
  )
  warn output unless output.empty?
  raise "gem install failed: #{error}\n#{output}" unless status.success?

  documentation_root = File.join(install_root, "doc", "#{spec.name}-#{spec.version}")
  rdoc_root = File.join(documentation_root, "rdoc")
  ri_root = File.join(documentation_root, "ri")
  raise "RDoc output was not generated at #{rdoc_root}" unless Dir[File.join(rdoc_root, "**", "*.html")].any?
  raise "RI output was not generated at #{ri_root}" unless Dir[File.join(ri_root, "**", "*")].any? { |path| File.file?(path) }
  puts "Installed #{spec.full_name} with RDoc and RI documentation"
ensure
  FileUtils.rm_f(gem_path) if gem_path && File.file?(gem_path)
end
