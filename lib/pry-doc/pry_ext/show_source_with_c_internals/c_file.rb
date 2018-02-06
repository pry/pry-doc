class CFile
  SourceLocation = Struct.new(:file, :line, :original_symbol)

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
      symbol, line_number = v.split("\x7f")
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
