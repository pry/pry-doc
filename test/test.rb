direc = File.dirname(__FILE__)

require 'rubygems'
require 'pry'
require "#{direc}/../lib/pry-doc"
require "#{direc}/test_helper"
require 'bacon'
require 'set'

puts "Testing pry-doc version #{PryDoc::VERSION}..."
puts "Ruby version: #{RUBY_VERSION}"

describe PryDoc do
  describe "core C methods" do
    it 'should look up core (C) methods' do
      obj = Pry::MethodInfo.info_for(method(:puts))
      obj.source.should.not == nil
    end

    it 'should look up core (C) instance methods' do
      Module.module_eval do
        obj = Pry::MethodInfo.info_for(instance_method(:include))
        obj.source.should.not == nil
      end
    end
  end

  describe "eval methods" do
    it 'should return nil for eval methods' do
      eval("def hello; end")
      obj = Pry::MethodInfo.info_for(method(:hello))
      obj.should == nil
    end
  end

  describe "pure ruby methods" do
    it 'should look up ruby methods' do
      obj = Pry::MethodInfo.info_for(C.new.method(:message))
      obj.should.not == nil
    end

    it 'should look up ruby instance methods' do
      obj = Pry::MethodInfo.info_for(C.instance_method(:message))
      obj.should.not == nil
    end
  end

  describe "Ruby stdlib methods" do
    it "should look up ruby stdlib method" do
      obj = Pry::MethodInfo.info_for(Set.instance_method(:union))
      obj.should.not == nil
    end
  end

  describe "C stdlib methods" do
    it "should return nil for C stdlib methods" do
      obj = Pry::MethodInfo.info_for(Readline.method(:readline))
      obj.should == nil
    end
  end
end

