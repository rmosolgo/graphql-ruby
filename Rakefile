# frozen_string_literal: true
require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"
  t.pattern = "spec/**/*_spec.rb"
  t.warning = false
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task(default: [:test, :rubocop])

desc "Use Racc & Ragel to regenerate parser.rb & lexer.rb from configuration files"
task :build_parser do
  `rm -f lib/graphql/language/parser.rb lib/graphql/language/lexer.rb `
  `racc lib/graphql/language/parser.y -o lib/graphql/language/parser.rb`
  `ragel -R -F1 lib/graphql/language/lexer.rl`
end

namespace :site do
  desc "View the documentation site locally"
  task serve: :build_doc do
    require "jekyll"
    options = {
      "source"      => File.expand_path("guides"),
      "destination" => File.expand_path("guides/_site"),
      "watch"       => true,
      "serving"     => true
    }
    # Generate the site in server mode.
    puts "Running Jekyll..."
    Jekyll::Commands::Build.process(options)
    Jekyll::Commands::Serve.process(options)
  end

  desc "Commit the local site to the gh-pages branch and publish to GitHub Pages"
  task publish: :build_doc do
    # Ensure the gh-pages dir exists so we can generate into it.
    puts "Checking for gh-pages dir..."
    unless File.exist?("./gh-pages")
      puts "Creating gh-pages dir..."
      sh "git clone git@github.com:rmosolgo/graphql-ruby gh-pages"
    end

    # Ensure latest gh-pages branch history.
    Dir.chdir("gh-pages") do
      sh "git checkout gh-pages"
      sh "git pull origin gh-pages"
    end

    # Proceed to purge all files in case we removed a file in this release.
    puts "Cleaning gh-pages directory..."
    purge_exclude = [
      'gh-pages/.',
      'gh-pages/..',
      'gh-pages/.git',
      'gh-pages/.gitignore',
    ]
    FileList["gh-pages/{*,.*}"].exclude(*purge_exclude).each do |path|
      sh "rm -rf #{path}"
    end

    # Copy site to gh-pages dir.
    puts "Building site into gh-pages branch..."
    ENV['JEKYLL_ENV'] = 'production'
    require "jekyll"
    Jekyll::Commands::Build.process({
      "source"       => File.expand_path("guides"),
      "destination"  => File.expand_path("gh-pages"),
      "sass"         => { "style" => "compressed" }
    })

    File.open('gh-pages/.nojekyll', 'wb') { |f| f.puts(":dog: food.") }

    # Commit and push.
    puts "Committing and pushing to GitHub Pages..."
    sha = `git rev-parse HEAD`.strip
    Dir.chdir('gh-pages') do
      sh "git add ."
      sh "git commit --allow-empty -m 'Updating to #{sha}.'"
      sh "git push origin gh-pages"
    end
    puts 'Done.'
  end

  task :build_doc do
    require "yard"
    def to_rubydoc_url(path)
      "http://www.rubydoc.info/gems/graphql/" + path
        .gsub("::", "/")                        # namespaces
        .sub(/#(.+)$/, "#\\1-instance_method")  # instance methods
        .sub(/\.(.+)$/, "#\\1-class_method")    # class methods
    end
    puts "Preparing YARD docs for search index"
    registry = YARD::Registry.load!(".yardoc")
    files_target = "guides/yardoc"
    FileUtils.rm_rf(files_target)
    FileUtils.mkdir_p(files_target)

    docs = registry.all(:class, :module)
    docs.each do |code_object|
      if code_object.visibility == :private
        next
      end
      rubydoc_url = to_rubydoc_url(code_object.path)
      page_content = <<-PAGE
---
layout: doc_stub
search: true
title: #{code_object.path}
url: #{rubydoc_url}
rubydoc_url: #{rubydoc_url}
---

#{code_object.format.gsub(/-{2,}/, " ").gsub(/^\s+/, "")}
PAGE

      filename = code_object.path.gsub(/\W+/, "_")
      filepath = "guides/yardoc/#{filename}.md"
      File.write(filepath, page_content)
    end
    puts "Wrote #{docs.size} YARD docs to #{files_target}"
  end
end

namespace :bench do
  def prepare_benchmark
    $LOAD_PATH << "./lib" << "./spec/support"
    require_relative("./benchmark/run.rb")
  end

  desc "Benchmark the introspection query"
  task :query do
    prepare_benchmark
    GraphQLBenchmark.run("query")
  end

  desc "Benchmark validating the introspection query"
  task :validate do
    prepare_benchmark
    GraphQLBenchmark.run("validate")
  end

  desc "Generate a profile of the introspection query"
  task :profile do
    prepare_benchmark
    GraphQLBenchmark.profile
  end
end
