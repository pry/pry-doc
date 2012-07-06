dlext = Config::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

PROJECT_NAME = "pry-doc"

require 'rake/clean'
require 'rake/gempackagetask'
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
  s.add_dependency("yard","~>0.8.1")
  s.add_dependency("pry",">=0.9.9.6")
  s.add_development_dependency("bacon",">=1.1.0")
  s.require_path = 'lib'
  s.homepage = "http://banisterfiend.wordpress.com"
  s.has_rdoc = 'yard'
  s.files = Dir["ext/**/extconf.rb", "ext/**/*.h", "ext/**/*.c", "lib/**/*",
                     "test/*.rb", "HISTORY", "README.md", "Rakefile", ".gemtest"]
end

desc "run tests"
task :test do
  sh "bacon -k #{direc}/test/test.rb"
end

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

  Rake::GemPackageTask.new(spec) do |pkg|
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


