require_relative "show_source_with_c_internals/code_fetcher"

class ShowSourceWithCInternals < Pry::Command::ShowSource
  def options(opt)
    super(opt)
    opt.on :c, "c-source", "Show source of a C symbol in MRI"
  end

  def show_c_source
    if opts.present?(:all)
      result = CodeFetcher.new(opts).fetch_all_definitions(obj_name)
    else
      result = CodeFetcher.new(opts).fetch_first_definition(obj_name)
    end
    if result
      _pry_.pager.page result
    else
      raise Pry::CommandError, no_definition_message
    end
  end

  def process
    if opts.present?(:c)
      show_c_source
      return
    else
      super
    end
  rescue Pry::CommandError
    show_c_source
  end

  Pry::Commands.add_command(ShowSourceWithCInternals)
end
