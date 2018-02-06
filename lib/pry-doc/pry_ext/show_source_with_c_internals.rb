require_relative "show_source_with_c_internals/c_extractor"

class ShowSourceWithCInternals < Pry::Command::ShowSource
  def options(opt)
    super(opt)
    opt.on :c, "c-source", "Show source of a C symbol in MRI"
  end

  def extract_c_source
    if opts.present?(:all)
      result = CExtractor.new(opts).show_all_definitions(obj_name)
    else
      result = CExtractor.new(opts).show_first_definition(obj_name)
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

  Pry::Commands.add_command(ShowSourceWithCInternals)
end
