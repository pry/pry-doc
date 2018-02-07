require 'fileutils'
require_relative 'c_file'
require_relative 'symbol_extractor'

class CodeFetcher
  include Pry::Helpers::Text

  attr_reader :opts
  attr_reader :symbol_extractor

  def initialize(opts)
    @opts = opts
    @symbol_extractor = SymbolExtractor.new
  end

  def fetch_all_definitions(symbol)
    infos = self.class.symbol_map[symbol]
    return unless infos

    "".tap do |result|
      infos.count.times do |index|
        result << fetch_first_definition(symbol, index) << "\n"
      end
    end
  end

  def fetch_first_definition(symbol, index=nil)
    infos = self.class.symbol_map[symbol]
    return unless infos

    info = infos[index || 0]
    code = symbol_extractor.extract_code(info)

    "".tap do |result|
      result << "\n#{bold('From: ')}#{info.file} @ line #{info.line}:\n"
      result << "#{bold('Number of implementations:')} #{infos.count}\n" unless index
      result << "#{bold('Number of lines: ')} #{code.lines.count}\n\n"
      result << Pry::Code.new(code, start_line_for(info.line), :c).
                  with_line_numbers(use_line_numbers?).highlighted
    end
  end

  private

  def use_line_numbers?
    opts.present?(:b) || opts.present?(:l)
  end

  def start_line_for(line)
    if opts.present?(:'base-one')
      1
    else
      line || 1
    end
  end

  def self.ruby_container_folder
    File.expand_path("~/.pry.d/")
  end

  def self.install_and_setup_ruby_source
    puts "Downloading and setting up Ruby #{ruby_version} source..."
    FileUtils.mkdir_p(ruby_container_folder)
    FileUtils.cd(ruby_container_folder) do
      %x{ curl -L https://github.com/ruby/ruby/archive/v#{ruby_version}.tar.gz | tar xzvf - > /dev/null 2>&1 }
    end

    FileUtils.cd(File.join(ruby_container_folder, "ruby-#{ruby_version}")) do
      puts "Generating tagfile!"
      %x{ find . -type f -name "*.[chy]" | etags -  -o tags }
    end
    puts "...Finished!"
  end

  def self.tagfile
    ruby_path = File.join(ruby_container_folder, "ruby-#{ruby_version}")
    install_and_setup_ruby_source unless File.directory?(ruby_path)

    @tagfile ||= File.read(File.join(ruby_path, "tags"))
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
