##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine'
require 'erubis/engine/eruby'
require 'erubis/engine/ejava'


module Erubis


  ##
  ## processing instructions (PI) enhancer for XML
  ##
  module PIEnhancer   # :nodoc:

    def self.desc
      "use processing instructions (PI) instead of '<% %>'"
    end

    def language()
      raise NotImplementedError("#{self.class.name}#language() is not implemented.")
    end

    def compile(input)
      src = ""
      @preamble.nil? ? add_preamble(src) : (@preamble && (src << @preamble))
      #regexp = pattern_regexp(@pattern)
      #regexp = /(^[ \t]*)?<\?(\w+)(?::([:\w]+))?(.*?)\?>([ \t]*\r?\n)?/m
      #regexp = /(^[ \t]*)?<!--\#(\w+)(?::([:\w]+))?(.*?)\#-->([ \t]*\r?\n)?/m
      regexp = /(^[ \t]*)?<(?:!--)?\?(\w+)(?:-(\w[-\w]*))?(.*?)\?(?:--)?>([ \t]*\r?\n)?/m
      lang = language()
      pos = 0
      input.scan(regexp) do |lspace, pi_name, pi_arg, code, rspace|
        index = Regexp.last_match.begin(0)
        text = input[pos, index - pos]
        pos = index + $&.length()
        add_text(src, text) # unless text.empty?
        if pi_name == 'xml'      ## xml declaration
          add_xmldecl(src, code)
        elsif pi_name == lang    ## statement
          flag_trim = @trim && lspace && rspace
          code = "#{lspace}#{code}#{rspace}" if flag_trim
          add_text(src, lspace)  unless flag_trim
          add_pi_stmt(src, code, pi_name, pi_arg)
          add_text(src, rspace)  unless flag_trim
        else                     ## expression
          add_text(src, lspace)  if lspace
          add_pi_expr(src, code, pi_name, pi_arg)
          add_text(src, rspace)  if rspace
        end
      end
      rest = $' || input
      add_text(src, rest)
      @postamble.nil? ? add_postamble(src) : (@postamble && (src << @postamble))
      return "#{@header}#{src}#{@footer}"
    end

    def add_xmldecl(src, code)
      add_text(src, "<?xml #{code.strip}?>\n")
    end

    def add_pi_stmt(src, code, pi_name, pi_arg)
      case pi_arg
      when 'header' ;  @header = code;  return true
      when 'footer' ;  @footer = code;  return true
      when 'comment';  add_stmt(src, "\n" * code.count("\n")); return true
      end
      add_stmt(src, code)
    end

    def add_pi_expr(src, code, pi_name, pi_arg)
      case pi_name
      when 'v'  ;  add_expr_literal(src, code);  return true
      when 'e'  ;  add_expr_escaped(src, code);  return true
      else      ;  add_text("<?#{pi_name}-#{pi_arg}#{code}?>")
      end
      add_expr(src, code)
    end

  end  # end of PIEnhancer


  class PIEruby < Eruby   # :nodoc:
    include PIEnhancer
    include BiPatternEnhancer
    include EscapeEnhancer

    def language
      'rb'
    end

    #def escaped_expr(code)
    #  "escapeXml(#{code.strip})"
    #end

  end


  class PIEjava < Ejava   # :nodoc:
    include PIEnhancer
    include BiPatternEnhancer
    include EscapeEnhancer

    def language
      'java'
    end

    def escaped_expr(code)
      "escapeXml(#{code.strip})"
    end

  end


end
