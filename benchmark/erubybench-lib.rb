
module Erubis

  class Eruby2 < Eruby
    def finalize_src(src)
      #src << "\nprint _out.join; nil\n"
      src << "\n_out.join; ''\n"
    end
  end

  class ExprStrippedEruby < Eruby
    def add_expr(src, code, indicator)
      super(src, code.strip! || code, indicator)
    end
  end


  ##
  ## use $stdout
  ##
  class TinyStdoutEruby

    def initialize(input)
      @src = compile(input)
    end
    attr_reader :src

    def result(binding=TOPLEVEL_BINDING)
      eval @src, binding
    end

    EMBEDDED_PATTERN = /(.*?)<%(=+|\#)?(.*?)-?%>/m

    def compile(input)
      src = "_out = $stdout;"           # preamble
      input.scan(EMBEDDED_PATTERN) do |text, indicator, code|
        src << " _out << '" << escape_text(text) << "';"
        if !indicator              # <% %>
          src << code << ";"
        elsif indicator[0] == ?\#  # <%# %>
          n = code.count("\n")
          add_stmt(src, "\n" * n)
        else                       # <%= %>
          src << " _out << (" << code << ").to_s;"
        end
      end
      rest = $' || input
      src << " _out << '" << escape_text(rest) << "';"
      src << "\nnil\n"       # postamble
      return src
    end

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
    end

  end


  ##
  ## use print statement
  ##
  class TinyPrintEruby

    def initialize(input)
      @src = compile(input)
    end
    attr_reader :src

    def result(binding=TOPLEVEL_BINDING)
      eval @src, binding
    end

    EMBEDDED_PATTERN = /(.*?)<%(=+|\#)?(.*?)-?%>/m

    def compile(input)
      src = ""
      input.scan(EMBEDDED_PATTERN) do |text, indicator, code|
        src << " print '" << escape_text(text) << "';"
        if !indicator              # <% %>
          src << code << ";"
        elsif indicator[0] == ?\#  # <%# %>
          n = code.count("\n")
          add_stmt(src, "\n" * n)
        else                       # <%= %>
          src << " print((" << code << ").to_s);"
        end
      end
      rest = $' || input
      src << " print '" << escape_text(rest) << "';"
      src << "\nnil\n"
      return src
    end

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
    end

  end


  ##
  ## for test
  ##
  class Optimized2Eruby < Eruby   # :nodoc:

    def self.supported_properties()  # :nodoc:
      return super
    end

    def initialize(input, properties={})
      @initialized = false
      #@prev_is_expr = false
      super
    end

    protected

    def escape_text(text)
      text.gsub(/['\\]/, '\\\\\&')   # "'" => "\\'",  '\\' => '\\\\'
    end

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

    #def switch_to_expr(src)
    #  return if @prev_is_expr
    #  @prev_is_expr = true
    #  src << ' _out'
    #end

    #def switch_to_stmt(src)
    #  return unless @prev_is_expr
    #  @prev_is_expr = false
    #  src << ';'
    #end

    def add_preamble(src)
      @initialized = false
      #@prev_is_expr = false
    end

    def add_text(src, text)
      return if text.empty?
      if @initialized
        #switch_to_expr(src)
        #src << " << '" << escape_text(text) << "'"
        src << "_out << '" << escape_text(text) << "';"
      else
        src << "_out = '" << escape_text(text) << "';"
        @initialized = true
      end
    end

    def add_stmt(src, code)
      #switch_to_stmt(src) if @initialized
      #super
      src << code << ';'
    end

    def add_expr_literal(src, code)
      unless @initialized; src << "_out = ''"; @initialized = true; end
      #switch_to_expr(src)
      #src << " << (" << code << ").to_s"
      src << " _out << (" << code << ").to_s;"
    end

    def add_expr_escaped(src, code)
      unless @initialized; src << "_out = ''"; @initialized = true; end
      #switch_to_expr(src)
      #src << " << " << escaped_expr(code)
      src << " _out << " << escaped_expr(code) << ';'
    end

    def add_expr_debug(src, code)
      code.strip!
      s = (code.dump =~ /\A"(.*)"\z/) && $1
      src << ' $stderr.puts("*** debug: ' << s << '=#{(' << code << ').inspect}");'
    end

    def add_postamble(src)
      #super if @initialized
      src << "\n_out\n" if @initialized
    end

  end

end
