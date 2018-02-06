class CuteExtractor
  class << self
    attr_accessor :file_cache
  end
  @file_cache = {}

  def extract_code(info)
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

  def extract_struct(info)
    source_file = source_from_file(info.file)
    loop do
      code = source_file[info.line, offset].join
      return code if balanced?(code)
      offset += 1
    end
  end

  def extract_typedef_struct(info)
    source_file = source_from_file(info.file)
    offset = 1
    loop do
      code = source_file[info.line - offset..info.line].join
      return code if balanced?(code)
      offset += 1
    end
  end

  def extract_macro(info)
    source_file = source_from_file(info.file)
    offset = 1
    loop do
      code = source_file[info.line, offset].join
      return code unless source_file[info.line + offset - 1].strip.end_with?('\\')
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
      return code if balanced?(code)
      offset += 1
    end
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
      file_cache[file] = ["\n", *File.read(full_path_for(file)).lines]
    end
  end

  def full_path_for(file)
    File.join(File.expand_path("~/.pry.d/ruby-#{ruby_version}"), file)
  end

  # normalized
  def ruby_version
    RUBY_VERSION.tr(".", "_")
  end
end
