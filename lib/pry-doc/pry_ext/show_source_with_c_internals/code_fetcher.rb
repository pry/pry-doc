require 'fileutils'
require_relative 'c_file'
require_relative 'symbol_extractor'
require_relative 'ruby_source_installer'

module Pry::CInternals
  class CodeFetcher
    include Pry::Helpers::Text

    class << self
      attr_accessor :ruby_source_folder
      attr_accessor :ruby_source_installer
    end

    # The Ruby version that corresponds to a downloadable release
    # Note that after Ruby 2.1.0 they exclude the patchlevel from the release name
    def self.ruby_version
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.1.0")
        RUBY_VERSION.tr(".", "_")
      else
        RUBY_VERSION.tr(".", "_") + "_#{RUBY_PATCHLEVEL}"
      end
    end

    self.ruby_source_folder = File.join(File.expand_path("~/.pry.d"), "ruby-#{ruby_version}")
    self.ruby_source_installer = RubySourceInstaller.new(ruby_version, ruby_source_folder)

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
      @symbol_map ||= (
        parse_tagfile
        @c_files.each_with_object({}) do |v, h|
          h.merge!(v.symbols) { |k, old_val, new_val| old_val + new_val }
        end)
    end

    def self.parse_tagfile
      @c_files ||= tagfile.split("\f\n")[1..-1].map do |v|
        CFile.new(v, ruby_source_folder: ruby_source_folder).tap(&:process_symbols)
      end
    end

    def self.tagfile
      tags = File.join(ruby_source_folder, "TAGS")
      if !File.exists?(tags)
        ruby_source_installer.install
      end
      @tagfile ||= File.read(tags)
    end
  end
end
