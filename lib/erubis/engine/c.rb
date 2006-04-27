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

    def initialize(input, properties={})
      @indent = properties[:indent] || ''
      @out = properties[:out] || 'stdout'
      super
    end

    def init_src(src)
      src << "# 1 \"#{self.filename}\"\n" if self.filename
    end

    def escape_text(text)
      @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
      text.gsub!(/[\r\n\t"\\]/) { |m| @@table_[m] }
      return text
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

    def escaped_expr(code)
      return code.strip
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

    def finalize_src(src)
    end

  end


  #--
  #class XmlEc < Ec
  #  include EscapeEnhancer
  #end
  #++


end
