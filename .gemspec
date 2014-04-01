Gem::Specification.new do |s|
  s.name = "pry-doc"
  s.version = File.read "VERSION"

  s.authors     = ["John Mair (banisterfiend)", "Kyrylo Silin", "Chris Gahan"]
  s.email       = ["jrmair@gmail.com", "silin@kyrylo.org", "chris@ill-logic.com"]
  s.summary     = 'Extended documentation for Pry (Ruby C methods, on-the-fly documentation generation)'
  s.homepage    = "https://github.com/pry/pry-doc"
  s.license     = 'MIT'
  s.description = %{
Pry Doc is a Pry REPL plugin. It provides extended documentation support for the
REPL by means of improving the `show-doc` and `show-source` commands. With help
of the plugin the commands are be able to display the source code and the docs
of Ruby methods and classes implemented in C.
}

  s.require_paths = ["lib"]
  s.files         = `git ls-files`.split("\n")

  s.add_dependency 'yard', "~> 0.8"
  s.add_dependency 'pry',  "~> 0.9"

  # The pregenerated YARD docs of Ruby's C-code for your version of Ruby...
  s.add_dependency 'ruby-core-docs'
end
