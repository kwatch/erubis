##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for Scheme
  ##
  class Escheme < Engine

    def initialize(input, properties={})
      @func = properties[:func] || '_add'   # or 'display'
      super
    end

    def init_src(src)
      return unless @func == '_add'
      src << "(let ((_out '())) " + \
               "(define (_add x) (set! _out (cons x _out))) "
      #src << "(let* ((_out '())" + \
      #             " (_add (lambda (x) (set! _out (cons x _out))))) "
    end

    def escape_text(text)
      @table_ ||= { '"'=>'\\"', '\\'=>'\\\\' }
      text.gsub!(/["\\]/) { |m| @table_[m] }
      return text
    end

    def escaped_expr(code)
      return code.strip! || code
    end

    def add_text(src, text)
      src << "(#{@func} \"" << escape_text(text) << '")' unless text.empty?
    end

    def add_stmt(src, code)
      src << code
    end

    def add_expr_literal(src, code)
      src << "(#{@func} " << code.strip << ')'
    end

    def add_expr_escaped(src, code)
      src << "(#{@func} " << escaped_expr(code) << ')'
    end

    def add_expr_debug(src, code)
      s = (code.strip! || code).gsub(/\"/, '\\"')
      src << "(display \"*** debug: #{s}=\")(display #{code.strip})(display \"\\n\")"
    end

    def finish_src(src)
      return unless @func == '_add'
      src << "\n" unless src[-1] == ?\n
      src << "  (reverse _out))\n"
    end

  end


  #--
  #class XmlEscheme < Escheme
  #  include EscapeEnhancer
  #end
  #++


end
