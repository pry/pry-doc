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
      case info.symbol_type
      when :macro
        extract_macro(info)
      when :struct, :enum
        extract_struct(info)
      when :typedef_struct
        extract_typedef_struct(info)
      when :typedef_oneliner
        extract_oneliner(info)
      when :function
        extract_function(info)
      else
        # if we dont know what it is, just extract out a single line
        extract_oneliner(info)
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
      extract_code(info, direction: :reverse) do |code|
        return code if balanced?(code)
      end
    end

    def extract_oneliner(info)
      source_file = source_from_file(info.file)
      return source_file[info.line]
    end

    def extract_function(info)
      source_file = source_from_file(info.file)
      offset, start_line = 1, info.line

      if !complete_function_signature?(source_file[info.line]) && function_return_type?(source_file[info.line - 1])
        start_line = info.line - 1
        offset += 1
      end

      (0..4).each do |v|
        line = source_file[info.line + v]
        if line && line.strip.end_with?("{")
          offset += v
          break
        end
      end

      extract_code(info, offset: offset, start_line: start_line) do |code|
        return code if balanced?(code)
      end
    end

    def extract_code(info, offset: 1, start_line: info.line, direction: :forward, &block)
      source_file = source_from_file(info.file)

      code_proc = direction == :reverse ? -> { source_file[start_line - offset..info.line].join }
                  : -> { source_file[start_line, offset].join }

      loop do
        yield code_proc.()
        offset += 1
      end
    end

    def complete_function_signature?(str)
      str =~ /\w+\s*\*?\s+\w+\(/
    end

    def function_return_type?(str)
      str.strip =~ /\w\s*\*?$/
    end

    def balanced?(str)
      tokens = CodeRay.scan(str, :c).tokens.each_slice(2)
      token_count(tokens, '{') == token_count(tokens, '}')
    end

    def token_count(tokens, token)
      tokens.count { |v| v.first.to_s.include?(token) && v.last == :operator }
    end

    def source_from_file(file)
      # inject a leading "\n" to align array index and line number
      self.class.file_cache[file] ||= ["\n", *File.read(file).lines]
    end
  end
end
