##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for C
  ##
  class Ec < Engine

    def self.supported_properties()  # :nodoc:
      list = super
      list << [:indent, '',       "indent spaces (ex. '  ')"]
      list << [:out,    'stdout', "output stream name"]
      return list
    end

    def initialize(input, properties={})
      @indent = properties[:indent] || ''
      @out = properties[:out] || 'stdout'
      super
    end

    def add_preamble(src)
      src << "#line 1 \"#{self.filename}\"\n" if self.filename
    end

    def escape_text(text)
      @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
      text.gsub!(/[\r\n\t"\\]/) { |m| @@table_[m] }
      return text
    end

    def escaped_expr(code)
      @escape ||= "escape"
      code.strip!
      if code =~ /\A(\".*?\")\s*,\s*(.*)/
        return "#{$1}, #{@escape}(#{$2})"
      else
        return "#{@escape}(#{code})"
      end
    end

    def add_text(src, text)
      return if text.empty?
      src << (src.empty? || src[-1] == ?\n ? @indent : ' ')
      src << "fputs("
      i = 0
      text.each_line do |line|
        src << "\n" << @indent << '      ' if i > 0
        i += 1
        src << '"' << escape_text(line) << '"'
      end
      src << ", #{@out});"   #<< (text[-1] == ?\n ? "\n" : "")
      src << "\n" if text[-1] == ?\n
    end

    def add_stmt(src, code)
      src << code
    end

    def add_expr_literal(src, code)
      src << @indent if src.empty? || src[-1] == ?\n
      src << " fprintf(#{@out}, " << code.strip << ');'
    end

    def add_expr_escaped(src, code)
      src << @indent if src.empty? || src[-1] == ?\n
      src << " fprintf(#{@out}, " << escaped_expr(code) << ');'
    end

    def add_expr_debug(src, code)
      code.strip!
      s = nil
      if code =~ /\A\".*?\"\s*,\s*(.*)/
        s = $1.gsub(/[%"]/, '\\\1') + '='
      end
      src << @indent if src.empty? || src[-1] == ?\n
      src << " fprintf(stderr, \"*** debug: #{s}\" #{code});"
    end

    def add_postamble(src)
    end

  end


  class EscapedEc < Ec
    include EscapeEnhancer
  end


  #class XmlEc < Ec
  #  include EscapeEnhancer
  #end


end
