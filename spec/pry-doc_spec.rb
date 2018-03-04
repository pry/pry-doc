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
  describe Pry::CInternals::CodeFetcher do
    def decolor(str)
      Pry::Helpers::Text.strip_color(str)
    end

    before do
      described_class.symbol_map = nil
      described_class.ruby_source_folder = File.join(File.dirname(__FILE__), "fixtures/c_source")
    end

    context "no tags file exists" do
      it "attempts to install and setup ruby" do
        described_class.ruby_source_folder = File.join(File.dirname(__FILE__), "fishface")
        expect(described_class.ruby_source_installer).to receive(:install)

        # will try to read from the 'created' tags file, this will error, so rescue
        # (since we're stubbing out `install` no tags file
        # ever gets created)
        described_class.symbol_map rescue nil
      end
    end

    describe ".symbol_map" do
      it "generates the map with the correct symbols" do
        expect(described_class.symbol_map).to have_key("foo")
        expect(described_class.symbol_map).to have_key("baby")
        expect(described_class.symbol_map).to have_key("wassup")
        expect(described_class.symbol_map).to have_key("bar")
        expect(described_class.symbol_map).to have_key("baz")
        expect(described_class.symbol_map).to have_key("cute_enum_e")
        expect(described_class.symbol_map).to have_key("baby_enum")
        expect(described_class.symbol_map).to have_key("cutie_pie")
      end
    end

    describe "#fetch_all_definitions" do
      it "returns both code and file name" do
        file_ = described_class.symbol_map["foo"].first.file
        _, file = described_class.new.fetch_all_definitions("foo")
        expect(file).to eq file_
      end

      it "returns the code for all symbols" do
        code, = described_class.new.fetch_all_definitions("foo")
        expect(decolor code).to include <<EOF
int
foo(void) {
}
EOF

        expect(decolor code).to include <<EOF
char
foo(int*) {
  return 'a';
}
EOF
      end
    end

    describe "#fetch_first_definition" do
      it "returns both code and file name" do
        code, file = described_class.new.fetch_first_definition("wassup")
        expect(decolor code).to include "typedef int wassup;"
        expect(file).to eq File.join(__dir__, "fixtures/c_source/hello.c")
      end

      context "with line numbers" do
        context "normal style (actual line numbers)" do
          it "displays actual line numbers" do
            code, = described_class.new(line_number_style: :'line-numbers').fetch_first_definition("bar")
            expect(decolor code).to include <<EOF
11: enum bar {
12:   alpha,
13:   beta,
14:   gamma
15: };
EOF
          end

          context "base one style (line numbers start with 1)" do
            it "displays actual line numbers" do
              code, = described_class.new(line_number_style: :'base-one').fetch_first_definition("bar")
              expect(decolor code).to include <<EOF
1: enum bar {
2:   alpha,
3:   beta,
4:   gamma
5: };
EOF
            end
          end
        end
      end

      it "returns the code for a function" do
        code, = described_class.new.fetch_first_definition("foo")
        expect(decolor code).to include(<<EOF
int
foo(void) {
}
EOF
                                       ).or include <<EOF
char
foo(int*) {
  return 'a';
}
EOF
      end

      it "returns the code for an enum" do
        code, = described_class.new.fetch_first_definition("bar")
        expect(decolor code).to include <<EOF
enum bar {
  alpha,
  beta,
  gamma
};
EOF
      end

      it "returns the code for a macro" do
        code, = described_class.new.fetch_first_definition("baby")
        expect(decolor code).to include('#define baby do {')
        expect(decolor code).to include('printf("baby");')
        expect(decolor code).to include('while(0)')
      end

      it "returns the code for a typedef" do
        code, = described_class.new.fetch_first_definition("wassup")
        expect(decolor code).to include('typedef int wassup;')
      end

      it "returns the code for a struct" do
        code, = described_class.new.fetch_first_definition("baz")
        expect(decolor code).to include <<EOF
struct baz {
  int x;
  int y;
};
EOF
      end

      it "returns the code for a typedef'd struct" do
        code, = described_class.new.fetch_first_definition("cutie_pie")
        expect(decolor code).to include <<EOF
typedef struct {
  int lovely;
  char horse;
} cutie_pie;
EOF
      end

      it "returns the code for a typedef'd enum" do
        code, = described_class.new.fetch_first_definition("baby_enum")
        expect(decolor code).to include <<EOF
typedef enum cute_enum_e {
  lillybing,
  tote,
  lilt
} baby_enum;
EOF
      end

      context "function definitions" do
        context "return type is on same line" do
          subject do
            decolor described_class.new
                      .fetch_first_definition("tinkywinky")
                      .first
          end

          it do is_expected.to include <<EOF
void tinkywinky(void) {
}
EOF
          end
        end

        context "curly brackets on subsequent line" do
          subject do
            decolor described_class.new
                      .fetch_first_definition("lala")
                      .first
          end

          it do is_expected.to include <<EOF
void lala(void)
{
}
EOF
          end
        end

        context "return type on prior line and curly brackets on subsequent" do
          subject do
            decolor described_class.new
                      .fetch_first_definition("po")
                      .first
          end

          it do is_expected.to include <<EOF
int*
po(void)
{
}
EOF
          end
        end
      end
    end
  end

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
