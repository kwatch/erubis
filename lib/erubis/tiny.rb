##
## $Rev$
## $Release$
## $Copyright$
##

module Erubis

  ##
  ## tiny and the simplest implementation of eRuby
  ##
  ## ex.
  ##   eruby = TinyEruby.new(File.read('example.rhtml'))
  ##   print eruby.src                 # print ruby code
  ##   print eruby.result(binding())   # eval ruby code with Binding object
  ##   print eruby.evalute(context)    # eval ruby code with context object
  ##
  class TinyEruby

    def initialize(input=nil)
      @src = convert(input) if input
    end
    attr_reader :src

    EMBEDDED_PATTERN = /<%(=+|\#)?(.*?)-?%>/m

    def convert(input)
      src = "_buf = [];"           # preamble
      pos = 0
      input.scan(EMBEDDED_PATTERN) do |indicator, code|
        match = Regexp.last_match
        len   = match.begin(0) - pos
        text  = input[pos, len]
        pos   = match.end(0)
        src << " _buf << '" << escape_text(text) << "';"
        if !indicator              # <% %>
          src << code << ";"
        elsif indicator[0] == ?\#  # <%# %>
          n = code.count("\n")
          add_stmt(src, "\n" * n)
        else                       # <%= %>
          src << " _buf << (" << code << ").to_s;"
        end
      end
      rest = $' || input
      src << " _buf << '" << escape_text(rest) << "';"
      src << "\n_buf.join\n"       # postamble
      return src
    end

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
    end

    def result(binding=TOPLEVEL_BINDING)
      eval @src, binding
    end

    def evaluate(context=Object.new)
      if context.is_a?(Hash)
        obj = Object.new
        context.each do |k, v| obj.instance_variable_set("@#{k}", v) end
        context = obj
      end
      context.instance_eval @src
    end

  end



  module PI
  end

  class PI::TinyEruby

    def initialize(input=nil, options={})
      @escape  = options[:escape] || 'Erubis::XmlHelper.escape_xml'
      @src = convert(input) if input
    end

    attr_reader :src

    EMBEDDED_PATTERN = /(^[ \t]*)?<\?rb(\s.*?)\?>([ \t]*\r?\n)?|@(!*)?\{(.*?)\}@/m

    def convert(input)
      src = "_buf = [];"           # preamble
      pos = 0
      input.scan(EMBEDDED_PATTERN) do |lspace, stmt, rspace, indicator, expr|
        match = Regexp.last_match
        len   = match.begin(0) - pos
        text  = input[pos, len]
        pos   = match.end(0)
        src << " _buf << '" << escape_text(text) << "';"
        if stmt                # <?rb ... ?>
          if lspace && rspace
            src << "#{lspace}#{stmt}#{rspace}"
          else
            src << " _buf << '" << lspace << "';" if lspace
            src << stmt << ";"
            src << " _buf << '" << rspace << "';" if rspace
          end
        else                       # ${...}, $!{...}
          if indicator.nil? || indicator.empty?
            src << " _buf << " << @escape << "(" << expr << ");"
          elsif indicator == '!'
            src << " _buf << (" << expr << ").to_s;"
          end
        end
      end
      rest = $' || input
      src << " _buf << '" << escape_text(rest) << "';"
      src << "\n_buf.join\n"       # postamble
      return src
    end

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
    end

    def result(binding=TOPLEVEL_BINDING)
      eval @src, binding
    end

    def evaluate(context=Object.new)
      if context.is_a?(Hash)
        obj = Object.new
        context.each do |k, v| obj.instance_variable_set("@#{k}", v) end
        context = obj
      end
      context.instance_eval @src
    end

  end


end
