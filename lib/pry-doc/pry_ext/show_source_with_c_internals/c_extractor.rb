require 'fileutils'
require_relative 'c_file'

class CExtractor
  include Pry::Helpers::Text

  class << self
    attr_accessor :file_cache
  end
  @file_cache = {}

  attr_reader :opts

  def initialize(opts)
    @opts = opts
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

  def full_path_for(file)
    File.join(File.expand_path("~/.pry.d/ruby-#{ruby_version}"), file)
  end

  def source_from_file(file)
    if file_cache.key?(file)
      file_cache[file]
    else
      file_cache[file] = File.read(full_path_for(file)).lines
      file_cache[file].unshift("\n")
    end
  end

  def use_line_numbers?
    opts.present?(:b) || opts.present?(:l)
  end

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

    h = "\n#{bold('From: ')}#{info.file} @ line #{info.line}:\n"
    h << "#{bold('Number of implementations:')} #{count}\n" unless index
    h << "#{bold('Number of lines: ')} #{code.lines.count}\n\n"
    h << Pry::Code.new(code, start_line_for(info.line), :c).
           with_line_numbers(use_line_numbers?).highlighted
  end

  def start_line_for(line)
    if opts.present?(:'base-one')
      1
    else
      line || 1
    end
  end

  def self.install_and_setup_ruby_source
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

  def self.tagfile
    if !File.directory?(File.expand_path("~/.pry.d/ruby-#{ruby_version}"))
      install_and_setup_ruby_source
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
end
