# -*- encoding: utf-8 -*-

require './lib/pry-doc/version.rb'

Gem::Specification.new do |s|
  s.name = "pry-doc"
  s.version = PryDoc::VERSION

  s.authors = ["John Mair (banisterfiend)"]
  s.email = ["jrmair@gmail.com"]
  s.summary = "Provides YARD and extended documentation support for Pry"
  s.description = s.summary
  s.homepage = "https://github.com/pry/pry-doc"
  s.license = 'MIT'

  s.cert_chain = ["cert/kyrylo@gmail.com.cer.pem"]
  s.signing_key = File.expand_path "~/.gem/keys/kyrylo@gmail.com.key.pem"

  s.require_paths = ["lib"]
  s.files = `git ls-files`.split("\n")

  s.add_dependency 'yard', ">= 0.8"
  s.add_dependency 'pry', ">= 0.9"
  s.add_development_dependency 'latest_ruby', ">= 0"
  s.add_development_dependency 'bacon', ">= 1.1.0"
end
