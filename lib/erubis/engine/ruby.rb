##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for Ruby
  ##
  class Eruby < Engine

    def init_src(src)
      src << "_out = '';"
    end

    def escape_text(text)
      text.gsub(/['\\]/, '\\\\\&')   # "'" => "\\'",  '\\' => '\\\\'
    end

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

    def add_text(src, text)
      src << " _out << '" << escape_text(text) << "';" unless text.empty?
    end

    def add_stmt(src, code)
      src << code << ';'
    end

    def add_expr_literal(src, code)
      src << ' _out << (' << code << ').to_s;'
    end

    def add_expr_escaped(src, code)
      src << ' _out << ' << escaped_expr(code) << ';'
    end

    def add_expr_debug(src, code)
      code.strip!
      s = (code.dump =~ /\A"(.*)"\z/) && $1
      src << ' $stderr.puts("*** debug: ' << s << '=#{(' << code << ').inspect}");'
    end

    def finish_src(src)
      src << "\n_out\n"
    end

  end


  ##
  ## sanitize expression (<%= ... %>) by default
  ##
  class XmlEruby < Eruby
    include EscapeEnhancer
  end


  ## (obsolete)
  class FastEruby < Eruby
    include FastEnhancer
  end


  class StdoutEruby < Eruby
    include StdoutEnhancer
  end


  class PrintEruby < Eruby
    include PrintEnhancer
  end


  class ArrayBufferEruby < Eruby
    include ArrayBufferEnhancer
  end


  ## (obsolete)
  class FastXmlEruby < Eruby
    include FastEnhancer
    include EscapeEnhancer
  end


  class StdoutXmlEruby < Eruby
    include StdoutEnhancer
    include EscapeEnhancer
  end


  class PrintXmlEruby < Eruby
    include PrintEnhancer
    include EscapeEnhancer
  end


  class ArrayBufferXmlEruby < Eruby
    include ArrayBufferEnhancer
    include EscapeEnhancer
  end


end
