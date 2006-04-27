##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/engine'
require 'erubis/enhancer'


module Erubis


  ##
  ## engine for PHP
  ##
  class Ephp < Engine

    def initialize(input, properties={})
      super
    end

    #--
    #def init_src(src)
    #end
    #++

    def escape_text(text)
      return text.gsub!(/<\?xml\b/, '<<?php ?>?xml') || text
    end

    def add_text(src, text)
      src << escape_text(text)
    end

    def escaped_expr(code)
      return "htmlspecialchars(#{code.strip})"
    end

    def add_expr_literal(src, code)
      src << "<?php echo #{code.strip}; ?>"
    end

    def add_expr_escaped(src, code)
      src << "<?php echo #{escaped_expr(code)}; ?>"
    end

    def add_expr_debug(src, code)
      code.strip!
      s = code.gsub(/\'/, "\\'")
      src << "<?php error_log('*** debug: #{s}='.(#{code}), 0); ?>"
    end

    def add_stmt(src, code)
      src << "<?php"
      src << " " if code[0] != ?\ #
      if code[-1] == ?\n
        code.chomp!
        src << code << "?>\n"
      else
        src << code << "?>"
      end
    end

    def finalize_src(src)
    end

  end


  class XmlEphp < Ephp
    include EscapeEnhancer
  end


end
