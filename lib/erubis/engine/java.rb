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

    def self.supported_properties()   # :nodoc:
      list = super
      list << [:indent,   '',       "indent spaces (ex. '  ')"]
      list << [:out,      '_out',   "output buffer name"]
      #list << [:outclass, 'StringBuffer', "output buffer class (ex. 'StringBuilder')"]
      return list
    end

    def initialize(input, properties={})
      @indent = properties[:indent] || ''
      @out = properties[:out] || '_out'
      #@outclass = properties[:outclass] || 'StringBuffer'
      super
    end

    def init_src(src)
      #src << "#{@indent}#{@out} _out = new #{@outclass}();\n"
    end

    def escape_text(text)
      @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
      return text.gsub!(/[\r\n\t"\\]/) { |m| @@table_[m] } || text
    end

    def escaped_expr(code)
      return "escape(#{code.strip})"
    end

    def add_text(src, text)
      return if text.empty?
      src << (src.empty? || src[-1] == ?\n ? @indent : ' ')
      src << @out << ".append("
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
      src << ' ' << @out << '.append(' << code.strip << ');'
    end

    def add_expr_escaped(src, code)
      src << @indent if src.empty? || src[-1] == ?\n
      src << ' ' << @out << '.append(' << escaped_expr(code) << ');'
    end

    def add_expr_debug(src, code)
      code.strip!
      src << @indent if src.empty? || src[-1] == ?\n
      src << " System.err.println(\"*** debug: #{code}=\"+(#{code}));"
    end

    def finish_src(src)
      src << "\n" if src[-1] == ?;
      #src << @indent << "return " << @out << ".toString();\n"
    end

  end


  class XmlEjava < Ejava
    include EscapeEnhancer
  end


end
