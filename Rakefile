require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task default: :spec
task test: :spec

dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

PROJECT_NAME = "pry-doc"

require 'latest_ruby'
require 'rake/clean'
require "#{direc}/lib/#{PROJECT_NAME}/version"

desc "start pry with fixture c file"
task :pry_fixture do
  sh %{pry -I./lib -r pry-doc -e "Pry::CInternals::CodeFetcher.ruby_source_folder = './spec/fixtures/c_source'"}
end

desc "start pry with pry-doc code loaded"
task :pry do
  sh "pry -I./lib -r pry-doc"
end

desc "generate fixture etags"
task :etags do
  sh 'etags --no-members spec/fixtures/c_source/*.c -o spec/fixtures/c_source/TAGS'
end
desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall pry-doc" rescue nil
  sh "gem install #{direc}/pkg/pry-doc-#{PryDoc::VERSION}.gem --no-document"
end

desc "build all platform gems at once"
task :gems => :rmgems do
  mkdir_p "pkg"
  sh 'gem build *.gemspec'
  mv "pry-doc-#{PryDoc::VERSION}.gem", "pkg"
end

desc "remove all platform gems"
task :rmgems do
  rm_rf 'pkg'
end

desc "Build gemspec"
task :gemspec => "ruby:gemspec"

desc "Show version"
task :version do
  puts "PryDoc version: #{PryDoc::VERSION}"
end

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("#{direc}/pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end

def download_ruby(ruby)
  system "mkdir rubies"
  system "wget #{ ruby.link } --directory-prefix=rubies --no-clobber"
  File.join('rubies', ruby.filename)
end

def unpackage_ruby(path)
  system "mkdir rubies/ruby"
  system "tar xzvf #{ path } --directory=rubies/ruby"
end

def cd_into_ruby
  Dir.chdir(Dir['rubies/ruby/*'].first)
end

def generate_yard
  system %{
    bash -c "paste <(find . -maxdepth 1 -name '*.c') <(find ext -name '*.c') |
      xargs yardoc --no-output"
  }
end

def replace_existing_docs(ver)
  system %|mkdir -p ../../../lib/pry-doc/docs/#{ver} && cp -r .yardoc/* ../../../lib/pry-doc/docs/#{ver}|
  Dir.chdir(File.expand_path(File.dirname(__FILE__)))
end

def clean_up
  system "rm -rf rubies"
end

def generate_docs_for(ruby_ver, latest_ruby)
  path = download_ruby(latest_ruby)
  unpackage_ruby(path)
  cd_into_ruby
  generate_yard
  replace_existing_docs(ruby_ver)
  clean_up
end

desc "Generate the latest Ruby 2.0 docs"
task "gen20" do
  generate_docs_for('20', Latest.ruby20)
end

desc "Generate the latest Ruby 2.1 docs"
task "gen21" do
  generate_docs_for('21', Latest.ruby21)
end

desc "Generate the latest Ruby 2.2 docs"
task "gen22" do
  generate_docs_for('22', Latest.ruby22)
end

desc "Generate the latest Ruby 2.3 docs"
task "gen23" do
  generate_docs_for('23', Latest.ruby23)
end

desc "Generate the latest Ruby 2.4 docs"
task "gen24" do
  generate_docs_for('24', Latest.ruby24)
end

desc "Generate the latest Ruby 2.5 docs"
task "gen25" do
  generate_docs_for('25', Latest.ruby25)
end

desc "Generate the latest Ruby 2.6 docs"
task "gen26" do
  generate_docs_for('26', Latest.ruby26)
end

desc "Generate the latest Ruby 2.7 docs"
task "gen27" do
  generate_docs_for('27', Latest.ruby27)
end

desc "Generate the latest Ruby 3.0 docs"
task "gen30" do
  generate_docs_for('30', Latest.ruby30)
end

desc "Generate the latest Ruby 3.1 docs"
task "gen31" do
  generate_docs_for('31', Latest.ruby31)
end

desc "Generate the latest Ruby 3.2 docs"
task "gen32" do
  generate_docs_for('32', Latest.ruby32)
end
