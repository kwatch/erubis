##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for Java
  ##
  class Ejava < Engine

    def initialize(input, properties={})
      @indent = properties[:indent] || ''
      @out    = properties[:out] || '_out'
      @outclass = properties[:outclass] || 'StringBuffer'
      super
    end

    def init_src(src)
      src << "#{@indent}#{@outclass} _out = new #{@outclass}();\n"
    end

    def escape_text(text)
      @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
      text.gsub(/[\r\n\t"\\]/) { |m| @@table_[m] }
    end

    def escaped_expr(code)
      return code.strip
    end

    def add_text(src, text)
      return if text.empty?
      src << (src.empty? || src[-1] == ?\n ? @indent : ' ')
      src << "_out.append("
      i = 0
      text.each_line do |line|
        src << "\n" << @indent << '          + ' if i > 0
        i += 1
        src << '"' << escape_text(line) << '"'
      end
      src << ");" << (text[-1] == ?\n ? "\n" : "")
    end

    def add_stmt(src, code)
      src << code
    end

    def add_expr_literal(src, code)
      src << @indent if src.empty? || src[-1] == ?\n
      src << ' _out.append(' << code.strip << ');'
    end

    def add_expr_escaped(src, code)
      src << @indent if src.empty? || src[-1] == ?\n
      src << ' _out.append(' << escaped_expr(code) << ');'
    end

    def add_expr_debug(src, code)
      code.strip!
      src << @indent if src.empty? || src[-1] == ?\n
      src << " System.err.println(\"*** debug: #{code}=\"+(#{code}));"
    end

    def finalize_src(src)
      src << "\n" if src[-1] == ?;
      src << @indent << "return _out.toString();\n"
    end

  end


  #--
  #class XmlEjava < Compiler
  #  include EscapeEnhancer
  #end
  #++

end
