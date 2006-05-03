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
  ##   print eruby.result(binding())   # eval ruby code
  ##
  class TinyEruby

    def initialize(input)
      @src = compile(input)
    end
    attr_reader :src

    EMBEDDED_PATTERN = /(.*?)<%(=+|\#)?(.*?)-?%>/m

    def compile(input)
      src = "_out = [];"           # preamble
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
      src << "\n_out.join\n"       # postamble
      return src
    end

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
    end

    def result(binding=TOPLEVEL_BINDING)
      eval @src, binding
    end

  end

end
