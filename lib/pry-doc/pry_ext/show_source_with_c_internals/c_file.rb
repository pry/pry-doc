# Data looks like:
#
# thread.c,11784
# static VALUE rb_cThreadShield;<\x7f>86,2497
# static VALUE sym_immediate;<\x7f>88,2529
# static VALUE sym_on_blocking;<\x7f>89,2557

# First line is the name of the file
# Following lines are the symbols followed by line number with char 127 as separator.
module Pry::CInternals
  class CFile
    SourceLocation = Struct.new(:file, :line, :symbol_type)

    # Used to separate symbol from line number
    SYMBOL_SEPARATOR = "\x7f"
    ALTERNATIVE_SEPARATOR = "\x1"

    attr_accessor :symbols, :file_name
    attr_reader :ruby_source_folder

    def initialize(str, ruby_source_folder: nil)
      @ruby_source_folder = ruby_source_folder
      @lines = str.lines
      @file_name = @lines.shift.split(",").first
    end

    def process_symbols
      @symbols = @lines.each_with_object({}) do |v, h|
        sep = v.include?(ALTERNATIVE_SEPARATOR) ? ALTERNATIVE_SEPARATOR : SYMBOL_SEPARATOR
        symbol, line_number = v.split(sep)
        next if symbol.strip =~ /^\w+$/ # these symbols are usually errors in etags
        h[cleanup_symbol(symbol)] = [source_location_for(symbol, line_number)]
      end
    end

    private

    def source_location_for(symbol, line_number)
      SourceLocation.new(File.join(ruby_source_folder, @file_name),
                         cleanup_linenumber(line_number), symbol_type_for(symbol.strip))
    end

    def symbol_type_for(symbol)
      if symbol =~ /#\s*define/
        :macro
      elsif symbol =~ /\bstruct\b/
        :struct
      elsif symbol =~ /\benum\b/
        :enum
      elsif symbol.start_with?("}")
        :typedef_struct
      elsif symbol =~/^typedef.*;$/
        :typedef_oneliner
      elsif symbol =~ /\($/
        :function
      else
        :unknown
      end
    end

    def cleanup_symbol(symbol)
      symbol = symbol.split.last
      symbol.gsub(/\W/, '')
    end

    def cleanup_linenumber(line_number)
      line_number.split.first.to_i
    end
  end
end
