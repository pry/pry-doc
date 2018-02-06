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
    symbol.chomp("(").chomp("*").chomp(";")
  end

  def cleanup_linenumber(line_number)
    line_number.split.first.to_i
  end
end

class ShowSourceWithCInternals < Pry::Command::ShowSource
  def options(opt)
    super(opt)
    opt.on :c, "c-source", "Show source of a C symbol in MRI"
  end

  def extract_c_source
    if opts.present?(:all)
      result = ShowCSource.new.show_all_definitions(obj_name)
    else
      result = ShowCSource.new.show_first_definition(obj_name)
    end
    if result
      _pry_.pager.page result
    else
      raise CommandError, no_definition_message
    end
  end

  def process
    if opts.present?(:c)
      extract_c_source
      return
    else
      super
    end
  rescue Pry::CommandError
    extract_c_source
  end
end

class ShowCSource < Pry::Command::ShowSource
  match 'show-source'
  group 'Introspection'
  description 'show source'

  class << self
    attr_accessor :file_cache
  end
  @file_cache = {}

  def initialize(*)
    super
  end

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

  def extract_typedef_struct(info)
    source_file = source_from_file(info.file)
    offset = 1
    loop do
      code = source_file[info.line - offset..info.line].join
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

  def extract_typedef_oneliner(info)
    source_file = source_from_file(info.file)
    return source_file[info.line]
  end

  def extract_function(info)
    source_file = source_from_file(info.file)
    offset = 1

    if source_file[info.line] !~ /\w+\s+\w\(/ && source_file[info.line - 1].strip =~ /[\w\*]$/
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
      file_cache[file] = File.read(File.join(File.expand_path("~/.pry.d/ruby-#{ruby_version}"), file)).lines
      file_cache[file].unshift("\n")
    end
  end

  def use_line_numbers?
    opts.present?(:b) || opts.present?(:l)
  end

  def options(opt)
    super(opt)
    #      opt.on :c, "c-source", "Show source of a C symbol in MRI" if defined?(ShowCSource)
    # opt.on :l, "line-numbers", "Show line numbers"
    # opt.on :b, "base-one", "Show line numbers but start numbering at 1"
    # opt.on :a, :all,  "Show all definitions of the C function"
  end

  def process
    super
  rescue Pry::CommandError
    if opts.present?(:all)
      result = ShowCSource.new.show_all_definitions(obj_name)
    else
      result = ShowCSource.new.show_first_definition(obj_name)
    end
    if result
      _pry_.pager.page result
    else
      raise Pry::CommandError, no_definition_message
    end
  end

  #   infos = self.class.symbol_map[x]
  #   if infos.nil?
  #     output.puts "Error: Couldn't locate a definition for #{x}"
  #     return
  #   end

  #   if opts.present?(:all)
  #     result = show_all_definitions(infos)
  #   else
  #     result = show_first_definition(infos.first, infos.count)
  #   end

  #   _pry_.pager.page result
  # end

  def show_all_definitions(x)
    infos = self.class.symbol_map[x]
    return unless infos

    result = ""
    infos.count.times do |index|
      result << show_first_definition(x, index) << "\n"
    end
    result
  end

  def show_first_definition(x, index=nil)
    infos = self.class.symbol_map[x]
    return unless infos

    count = infos.count
    info = infos[index || 0]
    code = if info.original_symbol.start_with?("#define")
             extract_macro(info)
           elsif info.original_symbol =~ /\s*struct\s*/ || info.original_symbol.start_with?("enum")
             extract_struct(info)
           elsif info.original_symbol.start_with?("}")
             extract_typedef_struct(info)
           elsif info.original_symbol =~/^typedef.*;$/
             extract_typedef_oneliner(info)
           else
             extract_function(info)
           end

    h = "\n#{text.bold('From: ')}#{info.file} @ line #{info.line}:\n"
    h << "#{text.bold('Number of implementations:')} #{count}\n" unless index
    h << "#{text.bold('Number of lines: ')} #{code.lines.count}\n\n"
    h << Pry::Code.new(code, 1, :c).
           with_line_numbers(false).highlighted
  end

  def start_line_for(info)
    if opts.present?(:'base-one')
      1
    else
      info.line || 1
    end
  end

  def self.tagfile
    if !File.directory?(File.expand_path("~/.pry.d/ruby-#{ruby_version}"))
      puts "Downloading and setting up Ruby #{ruby_version} source..."
      FileUtils.mkdir_p(File.expand_path("~/.pry.d/"))
      FileUtils.cd(File.expand_path("~/.pry.d")) do
        %x{ curl -L https://github.com/ruby/ruby/archive/v#{ruby_version}.tar.gz | tar xzvf - > /dev/null 2>&1 }
      end

      FileUtils.cd(File.expand_path("~/.pry.d/ruby-#{ruby_version}")) do
        puts "Generating tagfile!"
        %x{ find . -type f -name "*.[chy]" | etags -  -o tags }
      end
      puts "...Finished!"
    end

    @tagfile ||= File.read(File.expand_path("~/.pry.d/ruby-#{ruby_version}/tags"))
  end

  def ruby_version
    self.class.ruby_version
  end

  # normalized
  def self.ruby_version
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

  Pry::Commands.add_command(ShowSourceWithCInternals)
end
