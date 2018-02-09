require 'fileutils'
require_relative 'c_file'
require_relative 'symbol_extractor'

module Pry::CInternals
  class CodeFetcher
    include Pry::Helpers::Text

    class << self
      attr_accessor :ruby_source_folder
    end

    # normalized
    def self.ruby_version() RUBY_VERSION.tr(".", "_") end

    self.ruby_source_folder = File.join(File.expand_path("~/.pry.d"), "ruby-#{ruby_version}")

    attr_reader :line_number_style
    attr_reader :symbol_extractor

    def initialize(line_number_style: nil)
      @line_number_style = line_number_style
      @symbol_extractor = SymbolExtractor.new(self.class.ruby_source_folder)
    end

    def fetch_all_definitions(symbol)
      infos = self.class.symbol_map[symbol]
      return unless infos

      result = ""
      infos.count.times do |index|
        result << fetch_first_definition(symbol, index).first << "\n"
      end

      return [result, infos.first.file]
    end

    def fetch_first_definition(symbol, index=nil)
      infos = self.class.symbol_map[symbol]
      return unless infos

      info = infos[index || 0]
      code = symbol_extractor.extract(info)

      result = ""
      result << "\n#{bold('From: ')}#{info.file} @ line #{info.line}:\n"
      result << "#{bold('Number of implementations:')} #{infos.count}\n" unless index
      result << "#{bold('Number of lines: ')} #{code.lines.count}\n\n"
      result << Pry::Code.new(code, start_line_for(info.line), :c).
                  with_line_numbers(use_line_numbers?).highlighted

      return [result, info.file]

    end

    private

    def use_line_numbers?
      !!line_number_style
    end

    def start_line_for(line)
      line_number_style == :'base-one' ? 1 : line || 1
    end

    def self.symbol_map
      parse_tagfile
      @symbol_map ||= @c_files.each_with_object({}) do |v, h|
        h.merge!(v.symbols) { |k, old_val, new_val| old_val + new_val }
      end
    end

    def self.parse_tagfile
      @c_files ||= tagfile.split("\f\n")[1..-1].map do |v|
        CFile.new(v, ruby_source_folder: ruby_source_folder).tap(&:process_symbols)
      end
    end

    def self.tagfile
      tags = File.join(ruby_source_folder, "tags")
      install_and_setup_ruby_source unless File.exists?(tags)

      @tagfile ||= File.read(tags)
    end

    def self.check_for_error(message)
      raise Pry::CommandError, message if $?.to_i != 0
    end

    def self.ask_for_install
      puts "Method/class Not found - do you want to install MRI sources to attempt to resolve the identifier there?\n(This allows the lookup of C internals) Y/N"

      if $stdin.gets !~ /^y/i
        puts "MRI sources not installed. To prevent being asked again, add `Pry.config.skip_mri_source = true` to your ~/.pryrc"
        raise Pry::CommandError, "No definition found."
      end
    end

    def self.install_and_setup_ruby_source
      ask_for_install
      puts "Downloading and setting up Ruby #{ruby_version} source..."
      FileUtils.mkdir_p(ruby_source_folder)
      FileUtils.cd(File.dirname(ruby_source_folder)) do
        %x{ curl -L https://github.com/ruby/ruby/archive/v#{ruby_version}.tar.gz | tar xzvf - > /dev/null 2>&1 }
        check_for_error("curl")
      end

      FileUtils.cd(ruby_source_folder) do
        puts "Generating tagfile!"
        %x{ find . -type f -name "*.[chy]" | etags - --no-members -o tags }
        check_for_error("find | etags")
      end
      puts "...Finished!"
    end
  end
end
