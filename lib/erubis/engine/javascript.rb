##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for JavaScript
  ##
  class Ejavascript < Engine

    def self.supported_properties()   # :nodoc:
      list = super
      #list << [:indent,   '',       "indent spaces (ex. '  ')"]
      #list << [:out,      '_out',   "output buffer name"]
      return list
    end

    def initialize(input, properties={})
      @indent = properties[:indent] || ''
      @out = properties[:out] || '_out'
      #@outclass = properties[:outclass] || 'StringBuffer'
      super
    end

    def add_preamble(src)
      src << "#{@indent}#{@out} = [];"
    end

    def escape_text(text)
      @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n\\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
      return text.gsub!(/[\r\n\t"\\]/) { |m| @@table_[m] } || text
    end

    #--
    #def escaped_expr(code)
    #  @escape ||= 'escape'
    #  return "#{@escape}(#{code.strip})"
    #end
    #++

    def add_indent(src, indent)
      src << (src.empty? || src[-1] == ?\n ? indent : ' ')
    end

    def add_text(src, text)
      return if text.empty?
      add_indent(src, @indent)
      src << @out << '.push("'
      s = escape_text(text)
      if s[-1] == ?\n
        s[-2, 2] = ''
        src << s << "\");\n"
      else
        src << s << "\");"
      end
    end

    def add_stmt(src, code)
      src << code
    end

    def add_expr_literal(src, code)
      add_indent(src, @indent)
      src << @out << '.push(' << code.strip << ');'
    end

    def add_expr_escaped(src, code)
      add_indent(src, @indent)
      src << @out << '.push(' << escaped_expr(code) << ');'
    end

    def add_expr_debug(src, code)
      add_indent(src, @indent)
      code.strip!
      src << "alert(\"*** debug: #{code}=\"+(#{code}));"
    end

    def add_postamble(src)
      src << "\n" if src[-1] == ?;
      src << @indent << 'document.write(' << @out << ".join(\"\"));\n"
    end

  end


  class EscapedEjavascript < Ejavascript
    include EscapeEnhancer
  end


  #class XmlEjavascript < Ejavascript
  #  include EscapeEnhancer
  #end


end
