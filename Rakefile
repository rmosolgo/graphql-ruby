require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"
  t.pattern = "spec/**/*_spec.rb"
  t.warning = false
end

task(default: :test)

def load_gem_and_dummy
  $:.push File.expand_path("../lib", __FILE__)
  $:.push File.expand_path("../spec", __FILE__)
  require "graphql"
  require "./spec/support/dairy_app"
end

task :console do
  require "irb"
  require "irb/completion"
  load_gem_and_dummy
  ARGV.clear
  IRB.start
end

desc "Use Racc & Ragel to regenerate parser.rb & lexer.rb from configuration files"
task :build_parser do
  `rm lib/graphql/language/parser.rb lib/graphql/language/lexer.rb `
  `racc lib/graphql/language/parser.y -o lib/graphql/language/parser.rb`
  `ragel -R lib/graphql/language/lexer.rl`
end

desc "Build the site, copy it to the gh-pages branch, and push the gh-pages branch"
task :deploy_site do
  # TODO: use master branch instead of site
  `git checkout gh-pages`
  `git checkout site -- site/`
  Dir.chdir "site" do
    `nanoc`
  end
  `cp -r site/output/ ./`
  `git add -A`
  `git commit -m "deploy site to gh-pages (automatic)"`
  `git push origin gh-pages`
  `git checkout site`
end
