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
  ## raised when method or function is not supported
  ##
  class NotSupportedError < ErubisError
  end


  ##
  ## (abstract) context object for Engine#evaluate
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



  module Generator

    def self.supported_properties()  # :nodoc:
      return [
              [:escapefunc,    nil,    "escape function name"],
            ]
    end

    attr_accessor :escapefunc

    def init_generator(properties={})
      @escapefunc = properties[:escapefunc]
    end


    ## (abstract) escape text string
    ##
    ## ex.
    ##   def escape_text(text)
    ##     return text.dump
    ##     # or return "'" + text.gsub(/['\\]/, '\\\\\&') + "'"
    ##   end
    def escape_text(text)
      not_implemented
    end

    ## return escaped expression code (ex. 'h(...)' or 'htmlspecialchars(...)')
    def escaped_expr(code)
      code.strip!
      return "#{@escapefunc}(#{code})"
    end

    ## (abstract) add @preamble to src
    def add_preamble(src)
      not_implemented
    end

    ## (abstract) add text string to src
    def add_text(src, text)
      not_implemented
    end

    ## (abstract) add statement code to src
    def add_stmt(src, code)
      not_implemented
    end

    ## (abstract) add expression literal code to src. this is called by add_expr().
    def add_expr_literal(src, code)
      not_implemented
    end

    ## (abstract) add escaped expression code to src. this is called by add_expr().
    def add_expr_escaped(src, code)
      not_implemented
    end

    ## (abstract) add expression code to src for debug. this is called by add_expr().
    def add_expr_debug(src, code)
      not_implemented
    end

    ## (abstract) add @postamble to src
    def add_postamble(src)
      not_implemented
    end


  end



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

    def convert_input(codebuf, input)
      not_implemented
    end

  end



  module Basic
  end

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
  ## Processing Instructions (PI) converter for XML
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
             ]
    end

    attr_accessor :pi, :prefix

    def init_converter(properties={})
      super(properties)
      @trim    = !(properties[:trim] == false)
      @pi      = properties[:pi] if properties[:pi]
      @prefix  = properties[:prefix]  || '$'
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



  module Evaluator

    def self.supported_properties    # :nodoc:
      return []
    end

    attr_accessor :src, :filename

    def init_evaluator(properties)
      @filename = properties[:filename]
    end

    def result(*args)
      raise NotSupportedError.new("evaluation of code except Ruby is not supported.")
    end

    def evaluate(*args)
      raise NotSupportedError.new("evaluation of code except Ruby is not supported.")
    end

  end


  ##
  ## evaluator for Ruby
  ##
  module RubyEvaluator
    include Evaluator

    def self.supported_properties    # :nodoc:
      list = Evaluator.supported_properties
      return list
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

  end



  ##
  ## (abstract) abstract engine class.
  ## subclass must include evaluator and converter module.
  ##
  class Engine
    #include Evaluator
    #include Converter
    #include Generator

    # convert input string and set it to @src
    def convert!(input)
      @src = convert(input)
    end

    def initialize(input=nil, properties={})
      #@input = input
      init_generator(properties)
      init_converter(properties)
      init_evaluator(properties)
      @src    = convert(input) if input
    end

    ## load file and create engine object
    def self.load_file(filename, properties={})
      input = File.open(filename, 'rb') { |f| f.read }
      input.untaint   # is it ok?
      properties[:filename] = filename
      engine = self.new(input, properties)
      return engine
    end


    ##
    ## helper method to convert and evaluate input text with context object.
    ## context may be Binding, Hash, or Object.
    ##
    def process(input, context=nil, filename=nil)
      code = convert(input)
      filename ||= '(erubis)'
      if context.is_a?(Binding)
        return eval(code, context, filename)
      else
        context = Context.new(context) if context.is_a?(Hash)
        return context.instance_eval(code, filename)
      end
    end


    ##
    ## helper method evaluate Proc object iwth contect object.
    ## context may be Binding, Hash, or Object.
    ##
    def process_proc(proc_obj, context=nil, filename=nil)
      if context.is_a?(Binding)
        filename ||= '(erubis)'
        return eval(proc_obj, context, filename)
      else
        context = Context.new(context) if context.is_a?(Hash)
        return context.instance_eval(&proc_obj)
      end
    end


  end  # end of class Engine


  ##
  ## (abstract) base engine class for Eruby, Eperl, Ejava, and so on.
  ## subclass must include generator.
  ##
  class Basic::Engine < Engine
    include Evaluator
    include Basic::Converter
    include Generator
  end


  class PI::Engine < Engine
    include Evaluator
    include PI::Converter
    include Generator
  end


end
