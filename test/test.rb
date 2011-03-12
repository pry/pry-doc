direc = File.dirname(__FILE__)

require 'rubygems'
require "#{direc}/../lib/pry-doc"
require 'bacon'
require 'pry'

puts "Testing pry-doc version #{PryDoc::VERSION}..." 
puts "Ruby version: #{RUBY_VERSION}"

describe PryDoc do
  it 'should look up core (C) methods' do
    obj = Pry::MethodInfo.yard_object_for(method(:puts))
    obj.source.should.not == nil
  end

  it 'should look up core (C) instance methods' do
    Module.module_eval do
      obj = Pry::MethodInfo.yard_object_for(instance_method(:include))
      obj.source.should.not == nil
    end
  end

  it 'should return nil for eval methods' do
    eval("def hello; end")
    
    obj = Pry::MethodInfo.yard_object_for(method(:hello))
    obj.should == nil
  end

  it 'should look up ruby methods' do
    c = Class.new do
      def message
      end
    end

    obj = Pry::MethodInfo.yard_object_for(c.new.method(:message))
    obj.should.not == nil
  end

  it 'should look up ruby instance methods' do
    c = Class.new do
      def message
      end
    end

    binding.pry

    obj = Pry::MethodInfo.yard_object_for(c.instance_method(:message))
    obj.should.not == nil
  end
end

