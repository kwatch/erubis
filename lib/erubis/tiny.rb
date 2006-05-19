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

    def initialize(input)
      @src = compile(input)
    end
    attr_reader :src

    EMBEDDED_PATTERN = /(.*?)<%(=+|\#)?(.*?)-?%>/m

    def compile(input)
      src = "_buf = [];"           # preamble
      input.scan(EMBEDDED_PATTERN) do |text, indicator, code|
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

end
