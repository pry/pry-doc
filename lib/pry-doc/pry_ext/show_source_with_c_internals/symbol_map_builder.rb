require_relative 'c_file'

module Pry::CInternals
  class SymbolMapBuilder
    attr_reader :tags_path
    attr_reader :ruby_source_folder

    def initialize(tags_path, ruby_source_folder)
      @tags_path = tags_path
      @ruby_source_folder = ruby_source_folder
    end

    def symbol_map
      parse_tagfile.each_with_object({}) do |v, h|
        h.merge!(v.symbols) { |k, old_val, new_val| old_val + new_val }
      end
    end

    def parse_tagfile
      tagfile.split("\f\n")[1..-1].map do |v|
        CFile.new(v, ruby_source_folder: ruby_source_folder).tap(&:process_symbols)
      end
    end

    def tagfile
      File.read(tags_path)
    end
  end
end
