##
## $Rev$
## $Release$
## $Copyright$
##

require 'abstract'

module Erubis


  ##
  ## convert
  ##
  module Converter

    attr_accessor :preamble, :postamble, :escape

    def self.supported_properties    # :nodoc:
      return [
              [:preamble,  nil,    "preamble (no preamble when false)"],
              [:postamble, nil,    "postamble (no postamble when false)"],
              [:escape,    nil,    "escape expression or not in default"],
             ]
    end

    def init_converter(properties={})
      @preamble  = properties[:preamble]
      @postamble = properties[:postamble]
      @escape    = properties[:escape]
    end

    ## convert input string into target language
    def convert(input)
      codebuf = ""    # or []
      @preamble.nil? ? add_preamble(codebuf) : (@preamble && (codebuf << @preamble))
      convert_input(codebuf, input)
      @postamble.nil? ? add_postamble(codebuf) : (@postamble && (codebuf << @postamble))
      return codebuf  # or codebuf.join()
    end

    protected


    ##
    ## (abstract) convert input to code
    ##
    def convert_input(codebuf, input)
      not_implemented
    end

  end



  module Basic
  end


  ##
  ## basic converter which supports '<% ... %>' notation.
  ##
  module Basic::Converter
    include Erubis::Converter

    def self.supported_properties    # :nodoc:
      return [
              [:pattern,  '<% %>', "embed pattern"],
              [:trim,      true,   "trim spaces around <% ... %>"],
             ]
    end

    attr_accessor :pattern, :trim

    def init_converter(properties={})
      super(properties)
      @pattern   = properties[:pattern]
      @trim      = properties[:trim] != false
    end

    #DEFAULT_REGEXP = /(.*?)(^[ \t]*)?<%(=+|\#)?(.*?)-?%>([ \t]*\r?\n)?/m
    DEFAULT_REGEXP = /(^[ \t]*)?<%(=+|\#)?(.*?)-?%>([ \t]*\r?\n)?/m

    ## return regexp of pattern to parse eRuby script
    def pattern_regexp(pattern=@pattern)
      if pattern.nil? || pattern == '<% %>'
        return DEFAULT_REGEXP
      else
        prefix, postfix = pattern.split()
        #return /(.*?)(^[ \t]*)?#{prefix}(=+|\#)?(.*?)-?#{postfix}([ \t]*\r?\n)?/m
        return /(^[ \t]*)?#{prefix}(=+|\#)?(.*?)-?#{postfix}([ \t]*\r?\n)?/m
      end
    end
    protected :pattern_regexp

    def convert_input(src, input)
      regexp = pattern_regexp(@pattern)
      pos = 0
      input.scan(regexp) do |lspace, indicator, code, rspace|
        match = Regexp.last_match()
        index = match.begin(0)
        text  = input[pos, index - pos]
        pos   = match.end(0)
        add_text(src, text)
        ## * when '<%= %>', do nothing
        ## * when '<% %>' or '<%# %>', delete spaces iff only spaces are around '<% %>'
        if !indicator               # <% %>
          if @trim && lspace && rspace
            add_stmt(src, "#{lspace}#{code}#{rspace}")
          else
            add_text(src, lspace) if lspace
            add_stmt(src, code)
            add_text(src, rspace) if rspace
          end
        elsif indicator[0] == ?\#   # <%# %>
          n = code.count("\n") + (rspace ? 1 : 0)
          if @trim && lspace && rspace
            add_stmt(src, "\n" * n)
          else
            add_text(src, lspace) if lspace
            add_stmt(src, "\n" * n)
            add_text(src, rspace) if rspace
          end
        else                        # <%= %>
          add_text(src, lspace) if lspace
          add_expr(src, code, indicator)
          add_text(src, rspace) if rspace
        end
      end
      rest = $' || input     # add input when no matched
      add_text(src, rest)
    end

    ## add expression code to src
    def add_expr(src, code, indicator)
      case indicator
      when '='
        @escape ? add_expr_escaped(src, code) : add_expr_literal(src, code)
      when '=='
        @escape ? add_expr_literal(src, code) : add_expr_escaped(src, code)
      when '==='
        add_expr_debug(src, code)
      end
    end

  end


  module PI
  end

  ##
  ## Processing Instructions (PI) converter for XML.
  ## this class converts '<?rb ... ?>' and '${...}' notation.
  ##
  module PI::Converter
    include Erubis::Converter

    def self.desc
      "use processing instructions (PI) instead of '<% %>'"
    end

    def self.supported_properties    # :nodoc:
      return [
              [:trim,      true,   "trim spaces around <% ... %>"],
              [:pi,        'rb',   "PI (Processing Instrunctions) name"],
              [:prefix,    '$',    "prefix char of expression pattern('${...}')"],
              [:pattern,  '<% %>', "embed pattern"],
             ]
    end

    attr_accessor :pi, :prefix

    def init_converter(properties={})
      super(properties)
      @trim    = !(properties[:trim] == false)
      @pi      = properties[:pi] if properties[:pi]
      @prefix  = properties[:prefix]  || '$'
      @pattern = properties[:pattern]
      @pattern = '<% %>' if @pattern.nil?  #|| @pattern == true
    end

    def convert(input)
      code = super(input)
      return @header || @footer ? "#{@header}#{code}#{@footer}" : code
    end

    protected

    def convert_input(codebuf, input)
      parse_stmts(codebuf, input)
    end

    def parse_stmts(codebuf, input)
      #regexp = pattern_regexp(@pattern)
      @pi ||= 'e'
      @stmt_pattern ||= /(^[ \t]*)?<\?#{@pi}(?:-(\w+))?(\s.*?)\?>([ \t]*\r?\n)?/m
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
      unless @expr_pattern
        ch = Regexp.escape(@prefix)
        if @pattern
          left, right = @pattern.split(' ')
          @expr_pattern = /#{ch}(!*)?\{(.*?)\}|#{left}(=+)(.*?)#{right}/
        else
          @expr_pattern = /#{ch}(!*)?\{(.*?)\}/
        end
      end
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
        @escape == false ? add_expr_literal(codebuf, code) : add_expr_escaped(codebuf, code)
      when  '!', '='         # $!{...} or <%= ... %>
        @escape == false ? add_expr_escaped(codebuf, code) : add_expr_literal(codebuf, code)
      when  '!!', '==='      # $!!{...} or <%=== ... %>
        add_expr_debug(codebuf, code)
      else
        # ignore
      end
    end

  end


end
