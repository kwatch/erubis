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
      list << [:buf,      '_buf',   "output buffer name"]
      list << [:bufclass, 'StringBuffer', "output buffer class (ex. 'StringBuilder')"]
      return list
    end

    def initialize(input, properties={})
      @indent = properties[:indent] || ''
      @buf = properties[:buf] || '_buf'
      @bufclass = properties[:bufclass] || 'StringBuffer'
      super
    end

    def add_preamble(src)
      src << "#{@indent}#{@bufclass} #{@buf} = new #{@bufclass}();"
    end

    def escape_text(text)
      @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
      return text.gsub!(/[\r\n\t"\\]/) { |m| @@table_[m] } || text
    end

    #--
    #def escaped_expr(code)
    #  @escape ||= 'escape'
    #  return "#{@escape}(#{code.strip})"
    #end
    #++

    def add_text(src, text)
      return if text.empty?
      src << (src.empty? || src[-1] == ?\n ? @indent : ' ')
      src << @buf << ".append("
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
      src << ' ' << @buf << '.append(' << code.strip << ');'
    end

    def add_expr_escaped(src, code)
      src << @indent if src.empty? || src[-1] == ?\n
      src << ' ' << @buf << '.append(' << escaped_expr(code) << ');'
    end

    def add_expr_debug(src, code)
      code.strip!
      src << @indent if src.empty? || src[-1] == ?\n
      src << " System.err.println(\"*** debug: #{code}=\"+(#{code}));"
    end

    def add_postamble(src)
      src << "\n" if src[-1] == ?;
      src << @indent << "return " << @buf << ".toString();\n"
    end

  end


  class EscapedEjava < Ejava
    include EscapeEnhancer
  end


  #class XmlEjava < Ejava
  #  include EscapeEnhancer
  #end


end
