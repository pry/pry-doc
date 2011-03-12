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
  module MethodInfo

    @doc_cache = {}
    class << self; attr_reader :doc_cache; end

    def self.receiver_notation_for(meth)
      if meth.owner.name
        #klassinst, klass = '#', meth.owner.name
        "#{meth.owner.name}##{meth.name}"
      else 
        #klassinst, klass = '.', meth.owner.to_s[/#<.+?:(.+?)>/, 1]
        "#{meth.owner.to_s[/#<.+?:(.+?)>/, 1]}.#{meth.name}"
      end
    end

    # Retrieve the YARD object that contains the method data.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [YARD::CodeObjects::MethodObject] The YARD data for the method.
    def self.yard_object_for(meth)
      return nil if is_eval_method?(meth)
      cache(meth)
      
      obj = YARD::Registry.at(receiver_notation_for(meth))

      # Stupidly, YARD thinks that some methods are on Object when
      # they're actually on Kernel; so try again on Object if Kernel fails.
      if obj.nil? && meth.owner == Kernel 
        obj = YARD::Registry.at("Object##{meth.name}")
      end

      obj
    end

    def self.is_eval_method?(meth)
      file, _ = meth.source_location
      
      if file =~ /(\(.*\))|<.*>/
        return true
      end
      false
    end

    # Cache the file that holds the method or return true if file is
    # already cached. Return false if the method cannot be cached -
    # i.e is a C method.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [Boolean] Whether the cache was successful.
    def self.cache(meth)
      file, _ = meth.source_location
      return if !file
      return if is_eval_method?(meth)
      return if doc_cache[File.expand_path(file)]

      log.enter_level(Logger::FATAL) do
        YARD.parse(file)
      end
      doc_cache[File.expand_path(file)] = true
    end
  end
end  


