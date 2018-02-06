require 'fileutils'
require_relative 'c_file'
require_relative 'cute_extractor'

class CExtractor
  include Pry::Helpers::Text

  attr_reader :opts
  attr_reader :cute_extractor

  def initialize(opts)
    @opts = opts
    @cute_extractor = CuteExtractor.new
  end

  def show_all_definitions(x)
    infos = self.class.symbol_map[x]
    return unless infos

    "".tap do |result|
      infos.count.times do |index|
        result << show_first_definition(x, index) << "\n"
      end
    end
  end

  def show_first_definition(x, index=nil)
    infos = self.class.symbol_map[x]
    return unless infos

    count = infos.count
    info = infos[index || 0]

    code = cute_extractor.extract_code(info)

    h = "\n#{bold('From: ')}#{info.file} @ line #{info.line}:\n"
    h << "#{bold('Number of implementations:')} #{count}\n" unless index
    h << "#{bold('Number of lines: ')} #{code.lines.count}\n\n"
    h << Pry::Code.new(code, start_line_for(info.line), :c).
           with_line_numbers(use_line_numbers?).highlighted
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
    ruby_path = File.expand_path("~/.pry.d/ruby-#{ruby_version}")
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
