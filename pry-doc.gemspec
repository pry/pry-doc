require './lib/pry-doc/version.rb'

Gem::Specification.new do |s|
  s.name = "pry-doc"
  s.version = PryDoc::VERSION

  s.authors = ["John Mair (banisterfiend)"]
  s.email = ["jrmair@gmail.com"]
  s.summary = 'Provides YARD and extended documentation support for Pry'
  s.description = <<DESCR
Pry Doc is a Pry REPL plugin. It provides extended documentation support for the
REPL by means of improving the `show-doc` and `show-source` commands. With help
of the plugin the commands are be able to display the source code and the docs
of Ruby methods and classes implemented in C.
documentation
DESCR
  s.homepage = "https://github.com/pry/pry-doc"
  s.license = 'MIT'

  s.require_paths = ["lib"]
  s.files = `git ls-files`.split("\n")

  s.required_ruby_version = '>= 2.0'

  s.add_dependency 'yard', "~> 0.9.11"
  s.add_dependency 'pry', "~> 0.11"
  s.add_development_dependency 'latest_ruby', '~> 2.0'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rake', "~> 10.0"
end
