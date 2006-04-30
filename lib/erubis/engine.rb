##
## $Rev$
## $Release$
## $Copyright$
##


module Erubis


  ##
  ## base error class
  ##
  class ErubisError < StandardError
  end


  ##
  ## base engine class
  ##
  class Engine

    def self.supported_properties    # :nodoc:
      return [
              [:pattern,  '<% %>', "embed pattern"],
              #[:filename,  nil,    "filename"],
              [:trim,      true,   "trim spaces around <% ... %>"],
              [:preamble,  nil,    "preamble (no preamble when false)"],
              [:postamble, nil,    "postamble (no postamble when false)"],
              [:escape,    nil,     "escape function name"],
             ]
    end

    def initialize(input, properties={})
      #@input    = input
      @pattern   = properties[:pattern]  || '<% %>'
      @filename  = properties[:filename]
      @trim      = properties[:trim] != false
      @preamble  = properties[:preamble]
      @postamble = properties[:postamble]
      @escape    = properties[:escape]
      @src       = compile(input) if input
    end
    attr_reader :src
    attr_accessor :filename

    def self.load_file(filename, properties={})
      input = File.open(filename, 'rb') { |f| f.read }
      input.untaint   # is it ok?
      properties[:filename] = filename
      engine = self.new(input, properties)
      return engine
    end

    def result(_binding=TOPLEVEL_BINDING)
      _filename = @filename || '(erubis)'
      eval @src, _binding, _filename
    end

    def evaluate(_context={})
      ## load _context data as local variables by eval
      eval _context.keys.inject("") { |s, k| s << "#{k.to_s} = _context[#{k.inspect}];" }
      return result(binding())
    end

    DEFAULT_REGEXP = /(.*?)(^[ \t]*)?<%(=+|\#)?(.*?)-?%>([ \t]*\r?\n)?/m

    def pattern_regexp(pattern=@pattern)
      if pattern == '<% %>'
        return DEFAULT_REGEXP
      else
        prefix, postfix = pattern.split()
        return /(.*?)(^[ \t]*)?#{prefix}(=+|\#)?(.*?)-?#{postfix}([ \t]*\r?\n)?/m
      end
    end

    def compile(input)
      src = ""
      @preamble.nil? ? add_preamble(src) : (@preamble && (src << @preamble))
      regexp = pattern_regexp(@pattern)
      input.scan(regexp) do |text, lspace, indicator, code, rspace|
        ## * when '<%= %>', do nothing
        ## * when '<% %>' or '<%# %>', delete spaces iff only spaces are around '<% %>'
        if indicator && indicator[0] == ?=
          flag_trim = false
        else
          flag_trim = @trim && lspace && rspace
        end
        #flag_trim = @trim && !(indicator && indicator[0]==?=) && lspace && rspace
        add_text(src, text)
        add_text(src, lspace) if !flag_trim && lspace
        if !indicator             # <% %>
          code = "#{lspace}#{code}#{rspace}" if flag_trim
          add_stmt(src, code)
        elsif indicator[0] == ?\# # <%# %>
          n = code.count("\n")
          n += rspace.count("\n") if rspace
          add_stmt(src, "\n" * n)
        else                      # <%= %>
          add_expr(src, code, indicator)
        end
        add_text(src, rspace) if !flag_trim && rspace
      end
      rest = $' || input     # add input when no matched
      add_text(src, rest)
      @postamble.nil? ? add_postamble(src) : (@postamble && (src << @postamble))
      return src
    end

    def compile!(input)
      @src = compile(input)
    end

    protected

    def escape_text(text)
      return text
    end

    def escaped_expr(code)
      @escape ||= 'escape'
      return "#{@escape}(#{code.strip})"
    end

    def add_preamble(src)
    end

    def add_text(src, text)
    end

    def add_stmt(src, code)
    end

    def add_expr(src, code, indicator)
      case indicator
      when '='
        add_expr_literal(src, code)
      when '=='
        add_expr_escaped(src, code)
      when '==='
        add_expr_debug(src, code)
      end
    end

    def add_expr_literal(src, code)
    end

    def add_expr_escaped(src, code)
    end

    def add_expr_debug(src, code)
    end

    def add_postamble(src)
    end

  end  # end of class Engine


end
