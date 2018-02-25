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

    private

    # \f\n  indicates a new C file boundary in the etags file.
    # The first line is the name of the C file, e.g foo.c
    # The successive lines contain information about the symbols for that file.
    def parse_tagfile
      tagfile.split("\f\n")[1..-1].map do |c_file_section|
        file_name, content = file_name_and_content_for(c_file_section)
        CFile.new(file_name: file_name, content: content, ruby_source_folder: ruby_source_folder)
          .tap(&:process_symbols)
      end
    end

    def file_name_and_content_for(c_file_section)
      file_name, *content = c_file_section.lines
      [clean_file_name(file_name), content]
    end

    def tagfile
      File.read(tags_path)
    end

    def clean_file_name(file_name)
      file_name.split(",").first
    end
  end
end
