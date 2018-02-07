# Data looks like:
#
# thread.c,11784
# static VALUE rb_cThreadShield;<\x7f>86,2497
# static VALUE sym_immediate;<\x7f>88,2529
# static VALUE sym_on_blocking;<\x7f>89,2557

# First line is the name of the file
# Following lines are the symbols followed by line number with char 127 as separator.
class CFile
  SourceLocation = Struct.new(:file, :line, :original_symbol)

  # Used to separate symbol from line number
  SYMBOL_SEPARATOR = "\x7f"

  attr_accessor :symbols, :file_name

  def self.from_str(str)
    new(str).tap(&:process_symbols)
  end

  def initialize(str)
    @lines = str.lines
    @file_name = @lines.shift.split(",").first
  end

  def process_symbols
    @symbols = @lines.map do |v|
      symbol, line_number = v.split(SYMBOL_SEPARATOR)
      [cleanup_symbol(symbol),
       [SourceLocation.new(@file_name, cleanup_linenumber(line_number), symbol.strip)]]
    end.to_h
  end

  private

  def cleanup_symbol(symbol)
    symbol = symbol.split.last
    symbol.chomp("(").chomp("*").chomp(";")
  end

  def cleanup_linenumber(line_number)
    line_number.split.first.to_i
  end
end
