##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for Perl
  ##
  class Eperl < Engine

    def self.supported_properties()  # :nodoc:
      list = super
      list << [:func, 'print', "function name"]
      return list
    end

    def initialize(input, options={})
      @func = options[:func] || 'print'
      super
    end

    #--
    #def init_src(src)
    #end
    #++

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
    end

    def add_text(src, text)
      src << @func << "('" << escape_text(text) << "'); " unless text.empty?
    end

    def escaped_expr(code)
      return "escape(#{code.strip})"
    end

    def add_expr_literal(src, code)
      src << @func << "(" << code.strip << "); "
    end

    def add_expr_escaped(src, code)
      src << @func << "(" << escaped_expr(code) << "); "
    end

    def add_expr_debug(src, code)
      code.strip!
      s = code.gsub(/\'/, "\\'")
      src << @func << "('*** debug: #{code}=', #{code}, \"\\n\");"
    end

    def add_stmt(src, code)
      src << code
    end

    def finish_src(src)
      src << "\n" unless src[-1] == ?\n
    end

  end


  class XmlEperl < Eperl
    include EscapeEnhancer
  end


end
