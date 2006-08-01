##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine'

module Erubis
  module PI
  end
end


module Erubis::PI


  ##
  ## processing instructions (PI) enhancer for XML
  ##
  module Enhancer   # :nodoc:


    def self.desc
      "use processing instructions (PI) instead of '<% %>'"
    end


    attr_accessor :pi_name

    attr_accessor :prefix


    def compile(input)
      codebuf = ''
      @preamble.nil? ? add_preamble(codebuf) : (@preamble && (codebuf << @preamble))
      parse_stmts(codebuf, input)
      @postamble.nil? ? add_postamble(codebuf) : (@postamble && (codebuf << @postamble))
      return @header || @footer ? "#{@header}#{codebuf}#{@footer}" : codebuf
    end


    def parse_stmts(codebuf, input)
      #regexp = pattern_regexp(@pattern)
      @pi_name ||= 'e'
      @stmt_pattern ||= /(^[ \t]*)?<\?#{@pi_name}(?:-(\w+))?(\s.*?)\?>([ \t]*\r?\n)?/m
      pos = 0
      input.scan(@stmt_pattern) do |lspace, pi_arg, code, rspace|
        match = Regexp.last_match
        index = match.begin(0)
        text = input[pos, index - pos]
        pos = match.end(0)
        parse_exprs(codebuf, text) # unless text.empty?
        if @trim && lspace && rspace
          add_pi_stmt(codebuf, "#{lspace}#{code}#{rspace}", pi_arg)
        else
          add_text(codebuf, lspace)
          add_pi_stmt(codebuf, code, pi_arg)
          add_text(codebuf, rspace)
        end
      end
      rest = $' || input
      parse_exprs(codebuf, rest)
    end


    def parse_exprs(codebuf, input)
      @prefix ||= '$'
      #@expr_pattern ||= /#{Regexp.escape(@prefix)}(!*)?\{(.*?)\}/
      @expr_pattern ||= /#{Regexp.escape(@prefix)}(!*)?\{(.*?)\}|<%(=+)(.*?)%>/
      pos = 0
      input.scan(@expr_pattern) do |indicator1, code1, indicator2, code2|
        indicator = indicator1 || indicator2
        code = code1 || code2
        match = Regexp.last_match
        index = match.begin(0)
        text = input[pos, index - pos]
        pos = match.end(0)
        add_text(codebuf, text) # unless text.empty?
        add_pi_expr(codebuf, code, indicator)
      end
      rest = $' || input
      add_text(codebuf, rest)
    end


    def add_pi_stmt(codebuf, code, pi_arg)
      case pi_arg
      when 'header' ;  @header = code
      when 'footer' ;  @footer = code
      when 'comment';  add_stmt(codebuf, "\n" * code.count("\n"))
      when 'value'  ;  add_expr_literal(codebuf, code)
      else          ;  add_stmt(codebuf, code)
      end
    end


    def add_pi_expr(codebuf, code, indicator)
      case indicator
      when  nil, '', '=='    # ${...} or <%== ... %>
        add_expr_escaped(codebuf, code)
      when  '!', '='         # $!{...} or <%= ... %>
        add_expr_literal(codebuf, code)
      when  '!!', '==='      # $!!{...} or <%=== ... %>
        add_expr_debug(codebuf, code)
      else
        # ignore
      end
    end


  end


end
