##
## $Rev$
## $Release$
## $Copyright$
##

require 'abstract'


module Erubis


  ##
  ## base error class
  ##
  class ErubisError < StandardError
  end


  ##
  ## .[abstract] context object for Engine#evaluate
  ##
  ## ex.
  ##   template = <<'END'
  ##   Hello <%= @user %>!
  ##   <% for item in @list %>
  ##    - <%= item %>
  ##   <% end %>
  ##   END
  ##
  ##   context = Erubis::Context.new(:user=>'World', :list=>['a','b','c'])
  ##   # or
  ##   # context = Erubis::Context.new
  ##   # context[:user] = 'World'
  ##   # context[:list] = ['a', 'b', 'c']
  ##
  ##   eruby = Erubis::Eruby.new(template)
  ##   print eruby.evaluate(context)
  ##
  class Context

    def initialize(hash=nil)
      hash.each do |name, value|
        self[name] = value
      end if hash
    end

    def [](key)
      return instance_variable_get("@#{key}")
    end

    def []=(key, value)
      return instance_variable_set("@#{key}", value)
    end

    def keys
      return instance_variables.collect { |name| name[1,name.length-1] }
    end

  end


  ##
  ## .[abstract] base engine class
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
      @pattern   = properties[:pattern]
      @filename  = properties[:filename]
      @trim      = properties[:trim] != false
      @preamble  = properties[:preamble]
      @postamble = properties[:postamble]
      @escape    = properties[:escape]
      @src       = compile(input) if input
    end
    attr_reader :src
    attr_accessor :filename

    ## load file and create engine object
    def self.load_file(filename, properties={})
      input = File.open(filename, 'rb') { |f| f.read }
      input.untaint   # is it ok?
      properties[:filename] = filename
      engine = self.new(input, properties)
      return engine
    end

    ## eval(@src) with binding object
    def result(_binding_or_hash=TOPLEVEL_BINDING)
      _arg = _binding_or_hash
      if _arg.is_a?(Hash)
        ## load _context data as local variables by eval
        eval _arg.keys.inject("") { |s, k| s << "#{k.to_s} = _arg[#{k.inspect}];" }
        _arg = binding()
      end
      return eval(@src, _arg, (@filename || '(erubis)'))
    end

    ## invoke context.instance_eval(@src)
    def evaluate(context=Context.new)
      context = Context.new(context) if context.is_a?(Hash)
      return context.instance_eval(@src, (@filename || '(erubis)'))
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

    ## compile input string into target language
    def compile(input)
      src = ""
      @preamble.nil? ? add_preamble(src) : (@preamble && (src << @preamble))
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
          #flag_trim = @trim && lspace && rspace
          #add_text(src, lspace) if !flag_trim && lspace
          #n = code.count("\n") + (rspace ? 1 : 0)
          #add_stmt(src, "\n" * n)
          #add_text(src, rspace) if !flag_trim && rspace
        else                        # <%= %>
          add_text(src, lspace) if lspace
          add_expr(src, code, indicator)
          add_text(src, rspace) if rspace
        end
        #if indicator && indicator[0] == ?=
        #  flag_trim = false
        #else
        #  flag_trim = @trim && lspace && rspace
        #end
        ##flag_trim = @trim && !(indicator && indicator[0]==?=) && lspace && rspace
        #add_text(src, text)
        #add_text(src, lspace) if !flag_trim && lspace
        #if !indicator             # <% %>
        #  code = "#{lspace}#{code}#{rspace}" if flag_trim
        #  add_stmt(src, code)
        #elsif indicator[0] == ?\# # <%# %>
        #  n = code.count("\n") + (rspace ? 1 : 0)
        #  add_stmt(src, "\n" * n)
        #else                      # <%= %>
        #  add_expr(src, code, indicator)
        #end
        #add_text(src, rspace) if !flag_trim && rspace
      end
      rest = $' || input     # add input when no matched
      add_text(src, rest)
      @postamble.nil? ? add_postamble(src) : (@postamble && (src << @postamble))
      return src
    end

    ## compile input string and set it to @src
    def compile!(input)
      @src = compile(input)
    end

    protected

    ## .[abstract] escape text string
    ##
    ## ex.
    ##   def escape_text(text)
    ##     return text.dump
    ##     # or return "'" + text.gsub(/['\\]/, '\\\\\&') + "'"
    ##   end
    def escape_text(text)
      not_implemented
    end

    ## .[abstract] return escaped expression code
    ##
    ## ex.
    ##   def escaped_expr(code)
    ##     @escape ||= 'escape'
    ##     return "#{@escape}(#{code.strip})"
    ##   end
    def escaped_expr(code)
      not_implemented
    end

    ## .[abstract] add @preamble to src
    def add_preamble(src)
      not_implemented
    end

    ## .[abstract] add text string to src
    def add_text(src, text)
      not_implemented
    end

    ## .[abstract] add statement code to src
    def add_stmt(src, code)
      not_implemented
    end

    ## add expression code to src
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

    ## .[abstract] add expression literal code to src. this is called by add_expr().
    def add_expr_literal(src, code)
      not_implemented
    end

    ## .[abstract] add escaped expression code to src. this is called by add_expr().
    def add_expr_escaped(src, code)
      not_implemented
    end

    ## .[abstract] add expression code to src for debug. this is called by add_expr().
    def add_expr_debug(src, code)
      not_implemented
    end

    ## .[abstract] add @postamble to src
    def add_postamble(src)
      not_implemented
    end

  end  # end of class Engine


end
