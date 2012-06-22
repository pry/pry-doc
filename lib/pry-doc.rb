# pry-doc.rb
# (C) John Mair (banisterfiend); MIT license

direc = File.dirname(__FILE__)

require "#{direc}/pry-doc/version"
require "yard"

if RUBY_VERSION =~ /1.9/
  YARD::Registry.load_yardoc("#{File.dirname(__FILE__)}/pry-doc/core_docs_19")
else
  YARD::Registry.load_yardoc("#{File.dirname(__FILE__)}/pry-doc/core_docs_18")
end

class Pry

  # do not use pry-doc if rbx is active
  if !Object.const_defined?(:RUBY_ENGINE) || RUBY_ENGINE !~ /rbx/
    self.config.has_pry_doc = true
  end

  module MethodInfo

    # Convert a method object into the `Class#method` string notation.
    # @param [Method, UnboundMethod] meth
    # @return [String] The method in string receiver notation.
    def self.receiver_notation_for(meth)
      if is_singleton?(meth)
        "#{meth.owner.to_s[/#<.+?:(.+?)>/, 1]}.#{meth.name}"
      else
        "#{meth.owner.name}##{meth.name}"
      end
    end

    # Retrives aliases of a method
    # @param [Method, UnboundMethod] meth The method object.
    # @return [String] The original name of method if aliased
    #                  otherwise, it would be similar to current name
    def self.aliases(meth)
      owner       = is_singleton?(meth) ? meth.receiver : meth.owner
      method_type = is_singleton?(meth) ? :method : :instance_method

      methods = Pry::Method.send(:all_from_common, owner, method_type, false).
                            map { |m| m.instance_variable_get(:@method) }

      methods.select { |m| owner.send(method_type,m.name) == owner.send(method_type,meth.name) }.
              reject { |m| m.name == meth.name }.
              map    { |m| owner.send(method_type,m.name) }
    end

    # Checks whether method is a singleton (i.e class method)
    # @param [Method, UnboundMethod] meth
    # @param [Boolean] true if singleton
    def self.is_singleton?(meth)
      meth.owner.ancestors.first != meth.owner
    end

    # Check whether the file containing the method is already cached.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [Boolean] Whether the method is cached.
    def self.cached?(meth)
      !!registry_lookup(meth)
    end

    def self.registry_lookup(meth)
      obj = YARD::Registry.at(receiver_notation_for(meth))

      if obj.nil?
        if !(aliases = aliases(meth)).empty?
          obj = YARD::Registry.at(receiver_notation_for(aliases.first))
        elsif meth.owner == Kernel
          # YARD thinks that some methods are on Object when
          # they're actually on Kernel; so try again on Object if Kernel fails.
          obj = YARD::Registry.at("Object##{meth.name}")
        end
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
      owner = is_singleton?(meth) ? meth.receiver : meth.owner

      begin
        owner_source_location, _ =  WrappedModule.new(owner).source_location
        break if owner_source_location != nil
        owner = eval(owner.namespace_name)
      end while !owner.nil?

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

