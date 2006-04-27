##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine'


module Erubis


  ##
  ## switch '<%= ... %>' to escaped and '<%== ... %>' to non-escaped
  ##
  ## ex.
  ##   class XmlEruby < Eruby
  ##     include EscapeEnhancer
  ##   end
  ##
  module EscapeEnhancer

    def self.included(klass)
      klass.class_eval <<-END
        alias _add_expr_literal add_expr_literal
        alias _add_expr_escaped add_expr_escaped
        alias add_expr_literal _add_expr_escaped
        alias add_expr_escaped _add_expr_literal
      END
    end

  end


  ## (obsolete)
  module FastEnhancer
  end


  ##
  ## use $stdout instead of string
  ##
  module StdoutEnhancer

    def init_src(src)
      src << "_out = $stdout;"
    end

    def finish_src(src)
      src << "\nnil\n"
    end

  end


  ##
  ## print function is available.
  ##
  ## Notice: use Eruby#evaluate() and don't use Eruby#result()
  ## to be enable print function.
  ##
  module PrintEnhancer

    def init_src(src)
      src << "@_out = _out = '';"
    end

    def print(*args)
      args.each do |arg|
        @_out << arg.to_s
      end
    end

  end


  ##
  ## return Array instead of String
  ##
  module ArrayEnhancer

    def init_src(src)
      src << "_out = [];"
    end

    def finish_src(src)
      src << "\n" unless src[-1] == ?\n
      src << "_out\n"
    end

  end


  ##
  ## use Array instead of String as buffer
  ##
  module ArrayBufferEnhancer

    def init_src(src)
      src << "_out = [];"
    end

    def finish_src(src)
      src << "\n" unless src[-1] == ?\n
      src << "_out.join()\n"
    end

  end


end
