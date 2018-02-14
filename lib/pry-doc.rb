require 'yard'

require 'pry-doc/version'
require 'pry-doc/pry_ext/method_info'

module PryDoc
  def self.load_yardoc(version)
    path = "#{File.dirname(__FILE__)}/pry-doc/docs/#{version}"
    unless File.directory?(path)
      puts "#{RUBY_ENGINE}/#{RUBY_VERSION} isn't supported by this pry-doc version"
    end

    # Do not use pry-doc if Rubinius is active.
    Pry.config.has_pry_doc = RUBY_ENGINE !~ /rbx/

    YARD::Registry.load_yardoc(path)
  end

  def self.root
    @root ||= File.expand_path(File.dirname(__dir__))
  end

  root
end

PryDoc.load_yardoc(RUBY_VERSION[0...3].sub!('.', ''))
