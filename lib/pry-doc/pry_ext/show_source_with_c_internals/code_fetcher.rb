require 'fileutils'
require_relative 'c_file'
require_relative 'symbol_extractor'

module Pry::CInternals
  class CodeFetcher
    include Pry::Helpers::Text

    class << self
      attr_accessor :ruby_source_folder
    end

    # The Ruby version that corresponds to a downloadable release
    # Note that after Ruby 2.1.0 they exclude the patchlevel from the release name
    def self.ruby_version
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.1.0")
        RUBY_VERSION.tr(".", "_")
      else
        RUBY_VERSION.tr(".", "_") + "_#{RUBY_PATCHLEVEL}"
      end
    end

    self.ruby_source_folder = File.join(File.expand_path("~/.pry.d"), "ruby-#{ruby_version}")

    attr_reader :line_number_style
    attr_reader :symbol_extractor

    def initialize(line_number_style: nil)
      @line_number_style = line_number_style
      @symbol_extractor = SymbolExtractor.new(self.class.ruby_source_folder)
    end

    def fetch_all_definitions(symbol)
      infos = self.class.symbol_map[symbol]
      return unless infos

      result = ""
      infos.count.times do |index|
        result << fetch_first_definition(symbol, index).first << "\n"
      end

      return [result, infos.first.file]
    end

    def fetch_first_definition(symbol, index=nil)
      infos = self.class.symbol_map[symbol]
      return unless infos

      info = infos[index || 0]
      code = symbol_extractor.extract(info)

      result = ""
      result << "\n#{bold('From: ')}#{info.file} @ line #{info.line}:\n"
      result << "#{bold('Number of implementations:')} #{infos.count}\n" unless index
      result << "#{bold('Number of lines: ')} #{code.lines.count}\n\n"
      result << Pry::Code.new(code, start_line_for(info.line), :c).
                  with_line_numbers(use_line_numbers?).highlighted

      return [result, info.file]

    end

    private

    def use_line_numbers?
      !!line_number_style
    end

    def start_line_for(line)
      line_number_style == :'base-one' ? 1 : line || 1
    end

    def self.symbol_map
      parse_tagfile
      @symbol_map ||= @c_files.each_with_object({}) do |v, h|
        h.merge!(v.symbols) { |k, old_val, new_val| old_val + new_val }
      end
    end

    def self.parse_tagfile
      @c_files ||= tagfile.split("\f\n")[1..-1].map do |v|
        CFile.new(v, ruby_source_folder: ruby_source_folder).tap(&:process_symbols)
      end
    end

    def self.tagfile
      tags = File.join(ruby_source_folder, "TAGS")
      install_and_setup_ruby_source unless File.exists?(tags)

      @tagfile ||= File.read(tags)
    end

    # @param [String] message Message to display on error
    # @param [&Block] block Optional assertion
    def self.check_for_error(message, &block)
      raise Pry::CommandError, message if $?.to_i != 0 || block && !block.call
    end

    def self.ask_for_install
      print "Identifier not found - do you want to install CRuby sources to attempt to resolve the identifier there?\nThis allows the lookup of C internals Y/N "

      if $stdin.gets !~ /^y/i
        puts "CRuby sources not installed. To prevent being asked again, add `Pry.config.skip_cruby_source = true` to your ~/.pryrc"
        raise Pry::CommandError, "No definition found."
      end
    end

    def self.install_and_setup_ruby_source
      ask_for_install
      puts "Downloading and setting up Ruby #{ruby_version} source..."
      download_ruby
      generate_tagfile
      puts "...Finished!"
    end

    # for windows support need to:
    # (1) curl -k --fail -L https://github.com/ruby/ruby/archive/v2_4_1.zip
    # need -k as insecure as don't have root certs
    # (2) 7z x v2_4_1.zip to extract it (via 7zip, choco install 7zip)
    # (3) generate etags with: dir /b /s *.c *.h *.y | etags - --no-members
    # (4) Done!
    def self.download_ruby
      FileUtils.mkdir_p(ruby_source_folder)
      FileUtils.cd(File.dirname(ruby_source_folder)) do
        %x{ #{curl_cmd} }
        check_for_error(curl_cmd) { Dir.entries(ruby_source_folder).count > 5 }
      end
    end

    def self.curl_cmd
      if Pry::Platform.windows?
        %{
          curl -k --fail -L -O https://github.com/ruby/ruby/archive/v#{ruby_version}.zip & 7z -y x v#{ruby_version}.zip
        }
      else
        "curl --fail -L https://github.com/ruby/ruby/archive/v#{ruby_version}.tar.gz | tar xzvf - 2> /dev/null"
      end
    end

    def self.etag_binary
      @etag_binary ||= if Pry::Platform.linux?
                         arch = RbConfig::CONFIG['arch'] =~ /i(3|6)86/ ? 32 : 64
                         File.join(PryDoc.root, "libexec/linux/etags-#{arch}")
                       elsif Pry::Platform.windows?
                         File.join(PryDoc.root, "libexec/windows/etags")
                       else
                         "etags"
                       end
    end

    def self.etag_cmd
      if Pry::Platform.windows?
        %{dir /b /s *.c *.h *.y | "#{etag_binary}" - --no-members}
      else
        "find . -type f -name '*.[chy]' | #{etag_binary} - --no-members"
      end
    end

    def self.generate_tagfile
      FileUtils.cd(ruby_source_folder) do
        puts "Generating tagfile!"
        %x{ #{etag_cmd} }
        check_for_error(etag_cmd) { File.size(File.join(ruby_source_folder, "TAGS")) > 500 }
      end
    end
  end
end
