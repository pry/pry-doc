module Pry::CInternals
  class SymbolExtractor
    class << self
      attr_accessor :file_cache
    end
    @file_cache = {}

    def initialize(ruby_source_folder)
      @ruby_source_folder = ruby_source_folder
    end

    def extract(info)
      if info.original_symbol.start_with?("#define")
        extract_macro(info)
      elsif info.original_symbol =~ /\s*(struct|enum)\s*/
        extract_struct(info)
      elsif info.original_symbol.start_with?("}")
        extract_typedef_struct(info)
      elsif info.original_symbol =~/^typedef.*;$/
        extract_typedef_oneliner(info)
      else
        extract_function(info)
      end
    end

    private

    def extract_macro(info)
      extract_code(info) do |code|
        return code unless code.lines.last.strip.end_with?('\\')
      end
    end

    def extract_struct(info)
      extract_code(info) do |code|
        return code if balanced?(code)
      end
    end

    def extract_typedef_struct(info)
      extract_code(info) do |code, direction: :reverse|
        return code if balanced?(code)
      end
    end

    def extract_typedef_oneliner(info)
      source_file = source_from_file(info.file)
      return source_file[info.line]
    end

    def extract_function(info)
      source_file = source_from_file(info.file)
      offset = 1
      start_line = info.line

      if !complete_function_signature?(source_file[info.line]) && function_return_type?(source_file[info.line - 1])
        start_line = info.line - 1
        offset += 1
      end

      if !source_file[info.line].strip.end_with?("{")
        offset += 1
      end

      extract_code(info, offset: offset, start_line: start_line) do |code|
        return code if balanced?(code)
      end
    end

    def extract_code(info, offset: 1, start_line: info.line, direction: :forward, &block)
      source_file = source_from_file(info.file)

      loop do
        code = if direction == :reverse
                 source_file[start_line - offset..info.line].join
               else
                 source_file[start_line, offset].join
               end
        yield code
        offset += 1
      end
    end

    def complete_function_signature?(str)
      str =~ /\w+\s*\*?\s+\w+\(/
    end

    def function_return_type?(str)
      str.strip =~ /[\w\*]$/
    end

    def balanced?(str)
      tokens = CodeRay.scan(str, :c).tokens.each_slice(2)
      token_count(tokens, /{/) == token_count(tokens, /}/)
    end

    def token_count(tokens, token)
      tokens.count { |v|  v.first =~ token && v.last == :operator }
    end

    def source_from_file(file)
      file_cache = self.class.file_cache
      if file_cache.key?(file)
        file_cache[file]
      else
        # inject a "\n" as first element to align array index and line number
        file_cache[file] = ["\n", *File.read(full_path_for(file)).lines]
      end
    end

    def full_path_for(file)
      File.join(@ruby_source_folder, file)
    end

    # normalized
    def ruby_version
      RUBY_VERSION.tr(".", "_")
    end
  end
end
