require_relative "show_source_with_c_internals/code_fetcher"

module Pry::CInternals
  class ShowSourceWithCInternals < Pry::Command::ShowSource
    def options(opt)
      super(opt)
      opt.on :c, "c-source", "Show source of a C identifier in MRI (rather than Ruby method of same name)"
    end

    def show_c_source
      if opts.present?(:all)
        result, file = CodeFetcher.new(line_number_style: line_number_style)
                         .fetch_all_definitions(obj_name)
      else
        result, file = CodeFetcher.new(line_number_style: line_number_style)
                         .fetch_first_definition(obj_name)
      end
      if result
        set_file_and_dir_locals(file)
        pry_instance.pager.page result
      else
        raise Pry::CommandError, no_definition_message
      end
    end

    def process
      if opts.present?(:c) && !pry_instance.config.skip_cruby_source
        show_c_source
        return
      else
        super
      end
    rescue Pry::CommandError
      raise if pry_instance.config.skip_cruby_source
      show_c_source
    end

    private

    # We can number lines with their actual line numbers
    # or starting with 1 (base-one)
    def line_number_style
      if opts.present?(:'base-one')
        :'base-one'
      elsif opts.present?(:'line-numbers')
        :'line-numbers'
      else
        nil
      end
    end

    Pry::Commands.add_command(ShowSourceWithCInternals)
  end
end
