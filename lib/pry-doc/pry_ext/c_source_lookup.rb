require 'fileutils'

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
    symbol.chomp("(")
  end

  def cleanup_linenumber(line_number)
    line_number.split.first.to_i
  end
end

class CExtractor
  class << self
    attr_accessor :file_cache
  end
  @file_cache = {}

  def balanced?(str)
    tokens = CodeRay.scan(str, :c).tokens.each_slice(2).to_a
    tokens.count { |v|
      v.first =~ /{/ && v.last == :operator } == tokens.count { |v|
      v.first =~ /}/ && v.last == :operator
    }
  end

  def extract_struct(info)
    source_file = source_from_file(info.file)

    offset = 1
    loop do
      code = source_file[info.line, offset].join
      break code if balanced?(code)
      offset += 1
    end
  end

  def extract_macro(info)
    source_file = source_from_file(info.file)
    offset = 1
    loop do
      code = source_file[info.line, offset].join
      break code unless source_file[info.line + offset - 1].strip.end_with?('\\')
      offset += 1
    end
  end

  def extract_function(info)
    source_file = source_from_file(info.file)
    offset = 1

    if source_file[info.line] !~ /\w+\s+\w\(/ && source_file[info.line - 1].strip =~ /\w$/
      start_line = info.line - 1
      offset += 1
    else
      start_line = info.line
    end

    if !source_file[info.line].strip.end_with?("{")
      offset += 1
    end

    loop do
      code = source_file[start_line, offset].join
      break code if balanced?(code)
      offset += 1
    end
  end

  def file_cache
    self.class.file_cache
  end

  def file_cache=(v)
    self.class.file_cache = v
  end

  def source_from_file(file)
    if file_cache.key?(file)
      file_cache[file]
    else
      file_cache[file] = File.read(File.expand_path(File.join(__dir__, "pry-c", "resources", "ruby", file))).lines
      file_cache[file].unshift("\n")
    end
  end

  def extract(x)
    infos = self.class.symbol_map[x]
    return unless infos

    infos.each do |info|
      output.puts "File: #{info.file} Line: #{info.line}\n\n"
      code = if info.original_symbol.start_with?("#define")
               extract_macro(info)
             elsif info.original_symbol.start_with?("struct") || info.original_symbol.start_with?("enum")
               extract_struct(info)
             else
               extract_function(info)
             end
    end
  end

  def self.tagfile
    if !File.directory?(File.expand_path("~/.pry.d/ruby-#{ruby_version}"))
      puts "Downloading and setting up Ruby #{ruby_version} source..."
      FileUtils.mkdir_p(File.expand_path("~/.pry.d/"))
      %x{ curl -L https://github.com/ruby/ruby/archive/v2_5_0.tar.gz | tar xzvf - > /dev/null 2>&1 }
      FileUtils.cd(File.expand_path("~/.pry.d/ruby-#{ruby_version}")) do
        %x{ find . -type f -name "*.[chy]" | etags -  -o tags > /dev/null 2>&1 }
      end
      puts "...Finished!"
    end

    @tagfile ||= File.read(File.expand_path("~/.pry.d/ruby-#{ruby_version}/tagfile"))
  end

  # normalized
  def ruby_version
    RUBY_VERSION.tr(".", "_")
  end

  def self.parse_tagfile
    @c_files ||= tagfile.split("\f\n")[1..-1].map do |v|
      CFile.from_str(v)
    end
  end

  def self.symbol_map
    parse_tagfile
    @symbol_map ||= @c_files.each_with_object({}) do |v, h|
      h.merge!(v.symbols) { |k, old_val, new_val| old_val + new_val }
    end
  end
end
