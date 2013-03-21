# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pry-doc"
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2013-03-21"
  s.description = "Provides YARD and extended documentation support for Pry"
  s.email = "jrmair@gmail.com"
  s.files = ["lib/pry-doc", "lib/pry-doc/version.rb", "lib/pry-doc/core_docs_20", "lib/pry-doc/core_docs_20/object_types", "lib/pry-doc/core_docs_20/proxy_types", "lib/pry-doc/core_docs_20/objects", "lib/pry-doc/core_docs_20/objects/root.dat", "lib/pry-doc/core_docs_20/checksums", "lib/pry-doc/core_docs_18", "lib/pry-doc/core_docs_18/object_types", "lib/pry-doc/core_docs_18/proxy_types", "lib/pry-doc/core_docs_18/objects", "lib/pry-doc/core_docs_18/objects/root.dat", "lib/pry-doc/core_docs_18/checksums", "lib/pry-doc/core_docs_19", "lib/pry-doc/core_docs_19/object_types", "lib/pry-doc/core_docs_19/proxy_types", "lib/pry-doc/core_docs_19/objects", "lib/pry-doc/core_docs_19/objects/root.dat", "lib/pry-doc/core_docs_19/checksums", "lib/pry-doc.rb", "README.md", "CHANGELOG.md", "Rakefile"]
  s.homepage = "http://banisterfiend.wordpress.com"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Provides YARD and extended documentation support for Pry"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<yard>, [">= 0.8"])
      s.add_runtime_dependency(%q<pry>, [">= 0.9"])
      s.add_development_dependency(%q<bacon>, [">= 1.1.0"])
    else
      s.add_dependency(%q<yard>, [">= 0.8"])
      s.add_dependency(%q<pry>, [">= 0.9"])
      s.add_dependency(%q<bacon>, [">= 1.1.0"])
    end
  else
    s.add_dependency(%q<yard>, [">= 0.8"])
    s.add_dependency(%q<pry>, [">= 0.9"])
    s.add_dependency(%q<bacon>, [">= 1.1.0"])
  end
end
