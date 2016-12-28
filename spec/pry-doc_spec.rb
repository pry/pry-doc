direc = File.dirname(__FILE__)

require 'pry'
require "#{direc}/../lib/pry-doc"
require "#{direc}/helper"
require "#{direc}/gem_with_cext/gems/sample"
require 'set'
require 'fileutils'
require 'readline'

puts "Testing pry-doc version #{PryDoc::VERSION}..."
puts "Ruby version: #{RUBY_VERSION}"

RSpec.describe PryDoc do

  describe "core C methods" do
    it 'should look up core (C) methods' do
      obj = Pry::MethodInfo.info_for(method(:puts))
      expect(obj.source).not_to be_nil
    end

    it 'should look up core (C) instance methods' do
      obj = Module.module_eval do
        Pry::MethodInfo.info_for(instance_method(:include))
      end
      expect(obj.source).not_to be_nil
    end

    it 'should look up core (C) class method (by Method object)' do
      obj = Module.module_eval do
        Pry::MethodInfo.info_for(Dir.method(:glob))
      end
      expect(obj.source).not_to be_nil
    end

    it 'should look up core (C) class method (by UnboundMethod object)' do
      obj = Module.module_eval do
        Pry::MethodInfo.info_for(class << Dir; instance_method(:glob); end)
      end
      expect(obj.source).not_to be_nil
    end
  end

  describe "eval methods" do
    it 'should return nil for eval methods' do
      TOPLEVEL_BINDING.eval("def hello; end")
      obj = Pry::MethodInfo.info_for(method(:hello))
      expect(obj).to be_nil
    end
  end

  describe "pure ruby methods" do
    it 'should look up ruby methods' do
      obj = Pry::MethodInfo.info_for(C.new.method(:message))
      expect(obj).not_to be_nil
    end

    it 'should look up ruby instance methods' do
      obj = Pry::MethodInfo.info_for(C.instance_method(:message))
      expect(obj).not_to be_nil
    end
  end

  describe "Ruby stdlib methods" do
    it "should look up ruby stdlib method" do
      obj = Pry::MethodInfo.info_for(Set.instance_method(:union))
      expect(obj).not_to be_nil
    end
  end

  describe "C ext methods" do

    it "should lookup C ext methods" do
      obj = Pry::MethodInfo.info_for(Sample.instance_method(:gleezor))
      expect(obj).not_to be_nil
    end

    it "should lookup aliased C ext methods" do
      obj = Pry::MethodInfo.info_for(Sample.instance_method(:remove))
      expect(obj).not_to be_nil
    end

    it "should lookup C ext instance methods even when its owners don't have any ruby methods" do
      obj = Pry::MethodInfo.info_for(Sample::A::B.instance_method(:gleezor))
      expect(obj).not_to be_nil
    end

    it "should lookup C ext class methods even when its owners don't have any ruby methods" do
      obj = Pry::MethodInfo.info_for(Sample::A::B.method(:gleezor))
      expect(obj).not_to be_nil
    end
  end

  describe "C stdlib methods" do
    it "finds them" do
      obj = Pry::MethodInfo.info_for(Readline.method(:readline))
      expect(obj).not_to be_nil
    end

    it "finds well hidden docs like BigDecimal docs" do
      require 'bigdecimal'
      obj = Pry::MethodInfo.info_for(BigDecimal.instance_method(:finite?))
      expect(obj).not_to be_nil
    end
  end

  describe ".aliases" do
    it "should return empty array if method does not have any alias" do
      aliases = Pry::MethodInfo.aliases(Sample.instance_method(:some_meth))
      expect(aliases).to be_empty
    end

    it "should return aliases of a (C) method" do
      orig = Sample.instance_method(:gleezor)
      copy = Sample.instance_method(:remove)

      aliases = Pry::MethodInfo.aliases(orig)
      expect(aliases).to eq([copy])

      aliases = Pry::MethodInfo.aliases(copy)
      expect(aliases).to eq([orig])
    end

    it "should return aliases of a ruby method" do
      C.class_eval { alias msg message }

      orig = C.instance_method(:message)
      copy = C.instance_method(:msg)

      aliases = Pry::MethodInfo.aliases(orig)
      expect(aliases).to eq([copy])

      aliases = Pry::MethodInfo.aliases(copy)
      expect(aliases).to eq([orig])
    end

    it "should return aliases of protected method" do
      orig = Sample.instance_method(:gleezor_1)
      copy = Sample.instance_method(:remove_1)

      aliases = Pry::MethodInfo.aliases(orig)
      expect(aliases).to eq([copy])
    end

    it "should return aliases of private method" do
      orig = Sample.instance_method(:gleezor_2)
      copy = Sample.instance_method(:remove_2)

      aliases = Pry::MethodInfo.aliases(orig)
      expect(aliases).to eq([copy])
    end

    it 'does not error when given a singleton method' do
      c = Class.new do
        def self.my_method; end
      end

      expect { Pry::MethodInfo.aliases(c.method(:my_method)) }.not_to raise_error
    end
  end

  describe ".gem_root" do
    it "should return the path to the gem" do
      path = Pry::WrappedModule.new(Sample).source_location[0]
      expect(Pry::MethodInfo.gem_root(path)).
        to eq(File.expand_path("gem_with_cext/gems", direc))
    end

    it "should not be fooled by a parent 'lib' or 'ext' dir" do
      path = "/foo/.rbenv/versions/1.9.3-p429/lib/ruby/gems/"\
             "1.9.1/gems/activesupport-4.0.2/lib/active_support/"\
             "core_ext/kernel/reporting.rb"

      expect(Pry::MethodInfo.gem_root(path))
        .to eq('/foo/.rbenv/versions/1.9.3-p429/lib/ruby/' \
               'gems/1.9.1/gems/activesupport-4.0.2')
    end
  end

  describe "1.9 and higher specific docs" do
    it "finds Kernel#require_relative" do
      obj = Pry::MethodInfo.info_for(Kernel.instance_method(:require_relative))
      expect(obj).not_to be_nil
    end
  end

  # For the time being, Pry doesn't define `mri_20?` helper method.
  if RUBY_VERSION =~ /2.0/ && RbConfig::CONFIG['ruby_install_name'] == 'ruby'
    describe "2.0 specific docs" do
      it "finds Module#refine" do
        obj = Pry::MethodInfo.info_for(Module.instance_method(:refine))
        expect(obj).not_to be_nil
      end
    end
  end

end
