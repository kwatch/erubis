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

    def initialize(input, options={})
      #@input    = input
      @pattern  = options[:pattern]  || '<% %>'
      @filename = options[:filename]
      @trim     = options[:trim] != false
      @src      = compile(input)
    end
    attr_reader :src
    attr_accessor :filename

    def self.load_file(filename, options={})
      input = File.open(filename, 'rb') { |f| f.read }
      input.untaint   # is it ok?
      options[:filename] = filename
      eruby = self.new(input, options)
      return eruby
    end

    def result(binding=TOPLEVEL_BINDING)
      filename = @filename || '(erubis)'
      eval @src, binding, filename
    end

    def evaluate(_context={})
      _evalstr = ''
      _context.keys.each do |key|
        _evalstr << "#{key.to_s} = _context[#{key.inspect}]\n"
      end
      eval _evalstr
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
      init_src(src)
      regexp = pattern_regexp(@pattern)
      input.scan(regexp) do |text, head_space, indicator, code, tail_space|
        ## * when '<%= %>', do nothing
        ## * when '<% %>' or '<%# %>', delete spaces iff only spaces are around '<% %>'
        if indicator && indicator[0] == ?=
          flag_trim = false
        else
          flag_trim = @trim && head_space && tail_space
        end
        #flag_trim = @trim && !(indicator && indicator[0]==?=) && head_space && tail_space
        add_text(src, text)
        add_text(src, head_space) if !flag_trim && head_space
        if !indicator             # <% %>
          code = "#{head_space}#{code}#{tail_space}" if flag_trim
          add_stmt(src, code)
        elsif indicator[0] == ?=  # <%= %>
          add_expr(src, code, indicator)
        else                      # <%# %>
          n = code.count("\n")
          n += tail_space.count("\n") if tail_space
          add_stmt(src, "\n" * n)
        end
        add_text(src, tail_space) if !flag_trim && tail_space
      end
      rest = $' || input
      add_text(src, rest)
      finish_src(src)
      return src
    end

    protected

    def escape_text(text)
      return text
    end

    def escaped_expr(code)
      return code
    end

    def init_src(src)
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

    def finish_src(src)
    end

  end  # end of class Engine


end
