dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

PROJECT_NAME = "pry-doc"

require 'latest_ruby'
require 'rake/clean'
require 'rubygems/package_task'
require "#{direc}/lib/#{PROJECT_NAME}/version"

CLOBBER.include("**/*.#{dlext}", "**/*~", "**/*#*", "**/*.log", "**/*.o")
CLEAN.include("ext/**/*.#{dlext}", "ext/**/*.log", "ext/**/*.o",
              "ext/**/*~", "ext/**/*#*", "ext/**/*.obj", "**/*#*", "**/*#*.*",
              "ext/**/*.def", "ext/**/*.pdb", "**/*_flymake*.*", "**/*_flymake")

def apply_spec_defaults(s)
  s.name = PROJECT_NAME
  s.summary = "Provides YARD and extended documentation support for Pry"
  s.version = PryDoc::VERSION
  s.date = Time.now.strftime '%Y-%m-%d'
  s.author = "John Mair (banisterfiend)"
  s.email = 'jrmair@gmail.com'
  s.description = s.summary
  s.add_dependency("yard",">=0.8")
  s.add_dependency("pry",">=0.9")
  s.add_development_dependency("latest_ruby")
  s.add_development_dependency("bacon",">=1.1.0")
  s.require_path = 'lib'
  s.homepage = "http://banisterfiend.wordpress.com"
  s.has_rdoc = 'yard'
  s.files = Dir["ext/**/extconf.rb", "ext/**/*.h", "ext/**/*.c", "lib/**/*",
                     "test/*.rb", "HISTORY", "README.md", "CHANGELOG.md",
                     "Rakefile", ".gemtest"]
  s.signing_key = '/.gem-private_key.pem'
  s.cert_chain = ['gem-public_cert.pem']
end

desc "run tests"
task :test do
  sh "bacon -k #{direc}/spec/pry-doc_spec.rb"
end
task :spec => :test

task :default => :test

desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall pry-doc" rescue nil
  sh "gem install #{direc}/pkg/pry-doc-#{PryDoc::VERSION}.gem"
end

namespace :ruby do
  spec = Gem::Specification.new do |s|
    apply_spec_defaults(s)
    s.platform = Gem::Platform::RUBY
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end

  desc  "Generate gemspec file"
  task :gemspec do
    File.open("#{spec.name}.gemspec", "w") do |f|
      f << spec.to_ruby
    end
  end
end

desc "build all platform gems at once"
task :gems => [:clean, :rmgems, "ruby:gem"]

desc "remove all platform gems"
task :rmgems => ["ruby:clobber_package"]

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
  system "cp -r .yardoc/* ../../../lib/pry-doc/core_docs_#{ ver }"
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

desc "Generate the latest Ruby 1.9 docs"
task "gen19" do
  generate_docs_for('19', Latest.ruby19)
end

desc "Generate the latest Ruby 2.0 docs"
task "gen20" do
  generate_docs_for('20', Latest.ruby20)
end
