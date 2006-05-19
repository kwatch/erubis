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

    def self.supported_properties()  # :nodoc:
      list = super
      list << [:func,  '_add',   "function name (ex. 'display')"]
      return list
    end

    def initialize(input, properties={})
      @func = properties[:func] || '_add'   # or 'display'
      super
    end

    def add_preamble(src)
      return unless @func == '_add'
      src << "(let ((_buf '())) " + \
               "(define (_add x) (set! _buf (cons x _buf))) "
      #src << "(let* ((_buf '())" + \
      #             " (_add (lambda (x) (set! _buf (cons x _buf))))) "
    end

    def escape_text(text)
      @table_ ||= { '"'=>'\\"', '\\'=>'\\\\' }
      text.gsub!(/["\\]/) { |m| @table_[m] }
      return text
    end

    def escaped_expr(code)
      @escape ||= 'escape'
      return "(#{@escape} #{code.strip})"
    end

    def add_text(src, text)
      return if text.empty?
      t = escape_text(text)
      if t[-1] == ?\n
        t[-1, 1] = ''
        src << "(#{@func} \"" << t << "\\n\")\n"
      else
        src << "(#{@func} \"" << t << '")'
      end
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

    def add_postamble(src)
      return unless @func == '_add'
      src << "\n" unless src[-1] == ?\n
      src << "  (reverse _buf))\n"
    end

  end


  class EscapedEscheme < Escheme
    include EscapeEnhancer
  end


  #class XmlEscheme < Escheme
  #  include EscapeEnhancer
  #end


end
