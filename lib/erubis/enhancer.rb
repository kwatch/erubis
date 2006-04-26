##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/eruby'


module Erubis


  ##
  ## helper for xml
  ##
  module XmlHelper

    module_function

    def escape_xml(obj)
      str = obj.to_s.dup
      #str = obj.to_s
      #str = str.dup if obj.__id__ == str.__id__
      str.gsub!(/&/, '&amp;')
      str.gsub!(/</, '&lt;')
      str.gsub!(/>/, '&gt;')
      str.gsub!(/"/, '&quot;')   #"
      return str
    end

    alias h escape_xml
    alias html_escape escape_xml

  end


  module PrivateHelper  # :nodoc:

    module_function

    def report_expr(src, code)
      code.strip!
      s = code.dump
      s.sub!(/\A"/, '')
      s.sub!(/"\z/, '')
      src << " $stderr.puts(\"** erubis: #{s} = \#{(#{code}).inspect}\");"
    end

  end


  ##
  ## convenient module to escape expression value ('<%= ... %>') by default
  ##
  ## ex.
  ##   class LatexEruby < Eruby
  ##     def self.escape(str)
  ##       return str.gsub(/[%\\]/, '\\\1')
  ##     end
  ##     def escaped_expr(expr_code)
  ##       return "LatexEruby.escape(#{expr_code})"
  ##     end
  ##   end
  ##
  module EscapeEnhancer

    protected

    ##
    ## abstract method to convert expression code into escaped
    ##
    ## ex.
    ##   def escaped_expr(code)
    ##     return "CGI.escapeHTML(#{code})"
    ##   end
    ##
    def escaped_expr(code)
      raise NotImplementedError.new("#{self.class.name}#escaped_expr() is not implemented.")
    end


    ##
    ## escape expression code ('<%= .... %>')
    ##
    ## * '<%= ... %>'  => escaped
    ## * '<%== ... %>' => not escaped
    ## * '<%=== ... %>' => report expression value into $stderr
    ##
    def add_src_expr(src, code, indicator)
      case indicator
      when '='    # <%= %>
        src << " _out << " << escaped_expr(code) << ";"
      when '=='   # <%== %>
        super
      when '==='  # <%=== %>
        PrivateHelper.report_expr(src, code)
      else
        # nothing
      end
    end

  end


  ## (obsolete)
  module FastEnhancer
  end


  ##
  ## use $stdout instead of string
  ##
  module StdoutEnhancer

    def initialize_src(src)
      src << "_out = $stdout;"
    end

    def finalize_src(src)
      src << "\nnil\n"
    end

  end


  ##
  ## print function is available.
  ##
  ## Notice: use Eruby#evaluate() and don't use Eruby#result()
  ## to be enable print function.
  ##
  module PrintEnhancer

    def initialize_src(src)
      src << "@_out = _out = '';"
    end

    def print(*args)
      args.each do |arg|
        @_out << arg.to_s
      end
    end

  end


  ##
  ## sanitize expression (<%= ... %>) by default
  ##
  class XmlEruby < Eruby
    include EscapeEnhancer

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

  end


  ## (obsolete)
  class FastEruby < Eruby
    include FastEnhancer
  end


  class StdoutEruby < Eruby
    include StdoutEnhancer
  end


  class PrintEruby < Eruby
    include PrintEnhancer
  end


  ## (obsolete)
  class FastXmlEruby < XmlEruby
    include FastEnhancer
  end


  class StdoutXmlEruby < XmlEruby
    include StdoutEnhancer
  end


  class PrintXmlEruby < XmlEruby
    include PrintEnhancer
  end


end
