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
    #include StringBufferEnhancer
    include ArrayBufferEnhancer

    def self.supported_properties()  # :nodoc:
      return super
    end

    def escape_text(text)
      text.gsub(/['\\]/, '\\\\\&')   # "'" => "\\'",  '\\' => '\\\\'
    end

    def escaped_expr(code)
      @escape ||= "Erubis::XmlHelper.escape_xml"
      return "#{@escape}(#{code})"
    end

    #--
    #def add_preamble(src)
    #  src << "_out = [];"
    #end
    #++

    def add_text(src, text)
      src << " _out << '" << escape_text(text) << "';" unless text.empty?
    end

    def add_stmt(src, code)
      #src << code << ';'
      src << code
      src << ';' unless code[-1] == ?\n
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

    #--
    #def add_postamble(src)
    #  src << "\n_out.join\n"
    #end
    #++

  end


  ##
  ## swtich '<%= %>' to escaped and '<%== %>' to not escaped
  ##
  class EscapedEruby < Eruby
    include EscapeEnhancer
  end


  ##
  ## sanitize expression (<%= ... %>) by default
  ##
  ## this is equivalent to EscapedEruby and is prepared only for compatibility.
  ##
  class XmlEruby < Eruby
    include EscapeEnhancer
  end


end
