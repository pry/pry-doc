# pry-doc.rb
# (C) John Mair (banisterfiend); MIT license

direc = File.dirname(__FILE__)

require "#{direc}/pry-doc/version"
require "yard"

class Pry

  # do not use pry-doc if rbx is active
  if !Object.const_defined?(:RUBY_ENGINE) || RUBY_ENGINE !~ /rbx/
    self.config.has_pry_doc = true
  end

  module MethodInfo

    # doc_cache will contain both
    #   3rd party gem yardocs +
    #   ruby core yardocs included in pry-doc
    @doc_cache = File.expand_path("~/.pry/yard-cache")

    class << self; attr_accessor :doc_cache; end

    # Convert a method object into the `Class#method` string notation.
    # @param [Method, UnboundMethod] meth
    # @return [String] The method in string receiver notation.
    def self.receiver_notation_for(meth)
      if meth.owner.ancestors.first == meth.owner
        "#{meth.owner.name}##{meth.name}"
      else
        "#{meth.owner.to_s[/#<.+?:(.+?)>/, 1]}.#{meth.name}"
      end
    end

    # Check whether the file containing the method is already cached.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [Boolean] Whether the method is cached.
    def self.cached?(meth)
      !!registry_lookup(meth)
    end

    def self.registry_lookup(meth)
      obj = YARD::Registry.at(receiver_notation_for(meth))

      # YARD thinks that some methods are on Object when
      # they're actually on Kernel; so try again on Object if Kernel fails.
      if obj.nil? && meth.owner == Kernel
        obj = YARD::Registry.at("Object##{meth.name}")
      end
      obj
    end

    # Retrieve the YARD object that contains the method data.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [YARD::CodeObjects::MethodObject] The YARD data for the method.
    def self.info_for(meth)
      cache(meth)
      registry_lookup(meth)
    end

    # Determine whether a method is an eval method.
    # @return [Boolean] Whether the method is an eval method.
    def self.is_eval_method?(meth)
      file, _ = meth.source_location
      if file =~ /(\(.*\))|<.*>/
        true
      else
        false
      end
    end

    # Attempts to find the c source files if method belongs to a gem
    # and use YARD to parse and cache the source files for display
    #
    # @param [Method, UnboundMethod] meth The method object.
    def self.parse_and_cache_if_gem_cext(meth)
      if gem_dir = find_gem_dir(meth)
        if c_files_found?(gem_dir)
          YARD.parse("#{gem_dir}/ext/**/*.c")
          YARD::Registry.save(:merge, @doc_cache)
        end
      end
    end

    # @param [String] root directory path of gem that method belongs to
    # @return [Boolean] true if c files exist?
    def self.c_files_found?(gem_dir)
      Dir.glob("#{gem_dir}/ext/**/*.c").count > 0
    end

    # @param [Method, UnboundMethod] meth The method object.
    # @return [String] root directory path of gem that method belongs to,
    #                  nil if could not be found
    def self.find_gem_dir(meth)
      owner_source_location, _ = WrappedModule.new(meth.owner).source_location
      if owner_source_location
        owner_source_location.split("/lib/").first
      else
        nil
      end
    end

    # Cache the file that holds the method or return immediately if file is
    # already cached. Return if the method cannot be cached -
    # i.e is a C stdlib method.
    # @param [Method, UnboundMethod] meth The method object.
    def self.cache(meth)
      file, _ = meth.source_location

      return if is_eval_method?(meth)
      return if cached?(meth)

      if !file
        parse_and_cache_if_gem_cext(meth)
        return
      end

      log.enter_level(Logger::FATAL) do
        YARD.parse(file)
      end
    end
  end
end

YARD::Registry.single_object_db = false

if File.exist?(Pry::MethodInfo.doc_cache)
  YARD::Registry.load_yardoc(Pry::MethodInfo.doc_cache)
else
  if RUBY_VERSION =~ /1.9/
    YARD::Registry.load_yardoc("#{File.dirname(__FILE__)}/pry-doc/core_docs_19")
    YARD::Registry.load_all
    YARD::Registry.save(:merge, Pry::MethodInfo.doc_cache)
  else
    YARD::Registry.load_yardoc("#{File.dirname(__FILE__)}/pry-doc/core_docs_18")
    YARD::Registry.load_all
    YARD::Registry.save(:merge, Pry::MethodInfo.doc_cache)
  end
end

