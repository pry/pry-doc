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

      "".tap do |result|
        infos.count.times do |index|
          result << fetch_first_definition(symbol, index).first << "\n"
        end

        return [result, full_path_for(infos.first.file)]
      end
    end

    def fetch_first_definition(symbol, index=nil)
      infos = self.class.symbol_map[symbol]
      return unless infos

      info = infos[index || 0]
      code = symbol_extractor.extract(info)

      "".tap do |result|
        result << "\n#{bold('From: ')}#{info.file} @ line #{info.line}:\n"
        result << "#{bold('Number of implementations:')} #{infos.count}\n" unless index
        result << "#{bold('Number of lines: ')} #{code.lines.count}\n\n"
        result << Pry::Code.new(code, start_line_for(info.line), :c).
                    with_line_numbers(use_line_numbers?).highlighted

        return [result, full_path_for(info.file)]
      end
    end

    private

    def full_path_for(file)
      File.join(self.class.ruby_source_folder, file)
    end

    def use_line_numbers?
      !!line_number_style
    end

    def start_line_for(line)
      if line_number_style == :'base-one'
        1
      else
        line || 1
      end
    end

    def self.symbol_map
      parse_tagfile
      @symbol_map ||= @c_files.each_with_object({}) do |v, h|
        h.merge!(v.symbols) { |k, old_val, new_val| old_val + new_val }
      end
    end

    def self.parse_tagfile
      @c_files ||= tagfile.split("\f\n")[1..-1].map do |v|
        CFile.from_str(v)
      end
    end

    def self.tagfile
      install_and_setup_ruby_source unless File.directory?(ruby_source_folder)

      @tagfile ||= File.read(File.join(ruby_source_folder, "tags"))
    end

    def self.install_and_setup_ruby_source
      puts "Downloading and setting up Ruby #{ruby_version} source..."
      FileUtils.mkdir_p(ruby_source_folder)
      FileUtils.cd(File.dirname(ruby_source_folder)) do
        %x{ curl -L https://github.com/ruby/ruby/archive/v#{ruby_version}.tar.gz | tar xzvf - > /dev/null 2>&1 }
      end

      FileUtils.cd(ruby_source_folder) do
        puts "Generating tagfile!"
        %x{ find . -type f -name "*.[chy]" | etags -  -o tags }
      end
      puts "...Finished!"
    end
  end
end
