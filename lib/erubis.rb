##
## $Rev$
## $Release$
## $Copyright$
##

##
## an implementation of eRuby
##
## * class Eruby - normal eRuby class
## * class XmlEruby - eRuby class which escape '&<>"' into '&amp;&lt;&gt;&quot;'
## * module StdoutEnhancer - use $stdout instead of String as output
## * module PrintEnhancer - enable to write print statement in <% ... %>
## * class OptimizedEruby - optimized Eruby class faster than FastEruby
## * class OptimizedXmlEruby - optimized XmlEruby class faster than FastXmlEruby
##
## example:
##   list = ['<aaa>', 'b&b', '"ccc"']
##   input = <<'END'
##    <ul>
##     <% for item in list %>
##      <li><%= item %>
##          <%== item %></li>
##     <% end %>
##    </ul>
##   END
##   eruby = Erubis::XmlEruby.new(input)  # or try OptimizedXmlEruby
##   puts "--- source ---"
##   puts eruby.src
##   puts "--- result ---"
##   puts eruby.result(binding())
##   # or puts eruby.evaluate(:list=>list)
##
## result:
##   --- source ---
##   _out = ""; _out << " <ul>\n"
##      for item in list
##   _out << "   <li>"; _out << Erubis::XmlEruby.escape( item ); _out << "\n"
##   _out << "       "; _out << ( item ).to_s; _out << "</li>\n"
##      end
##   _out << " </ul>\n"
##   _out
##   --- result ---
##    <ul>
##      <li>&lt;aaa&gt;
##          <aaa></li>
##      <li>b&amp;b
##          b&b</li>
##      <li>&quot;ccc&quot;
##          "ccc"</li>
##    </ul>
##

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

    def report_code(code, src)
      code.strip!
      s = code.dump
      s.sub!(/\A"/, '')
      s.sub!(/"\z/, '')
      src << " $stderr.puts(\"** erubis: #{s} = \#{(#{code}).inspect}\");"
    end

  end


  ##
  ## base class
  ##
  class Eruby

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

    #private

    def compile(input)
      src = ""
      initialize_src(src)
      prefix, postfix = @pattern.split()
      regexp = /(.*?)(^[ \t]*)?#{prefix}(=+|\#)?(.*?)-?#{postfix}([ \t]*\r?\n)?/m
      input.scan(regexp) do |text, head_space, indicator, code, tail_space|
        ## * when '<%= %>', do nothing
        ## * when '<% %>' or '<%# %>', delete spaces iff only spaces are around '<% %>'
        if indicator && indicator[0] == ?=
          flag_trim = false
        else
          flag_trim = @trim && head_space && tail_space
        end
        #flag_trim = @trim && !(indicator && indicator[0]==?=) && head_space && tail_space
        add_src_text(src, text)
        add_src_text(src, head_space) if !flag_trim && head_space
        if !indicator             # <% %>
          code = "#{head_space}#{code}#{tail_space}" if flag_trim
          add_src_code(src, code)
        elsif indicator[0] == ?=  # <%= %>
          add_src_expr(src, code, indicator)
        else                      # <%# %>
          n = code.count("\n")
          n += tail_space.count("\n") if tail_space
          add_src_code(src, "\n" * n)
        end
        add_src_text(src, tail_space) if !flag_trim && tail_space
      end
      rest = $' || input
      add_src_text(src, rest)
      finalize_src(src)
      return src
    end

    protected

    def initialize_src(src)
      src << "_out = '';"
    end

    def add_src_text(src, text)
      return if text.empty?
      text.gsub!(/['\\]/, '\\\\\&')   # "'" => "\\'",  '\\' => '\\\\'
      src << " _out << '" << text << "';"
    end

    def add_src_expr(src, code, indicator)
      src << ' _out << (' << code << ').to_s;'
    end

    def add_src_code(src, code)
      src << code << ';'
    end

    def finalize_src(src)
      src << "\n_out\n"
    end

  end  # end of class Eruby


  ##
  ## abstract base class to escape expression (<%= ... %>)
  ##
  class EscapedEruby < Eruby

    protected
  
    ## abstract method
    def escaped_expr(code)
      raise NotImplementedError.new("#{self.class.name}#escaped_expr() is not implemented.")
    end

    def add_src_expr(src, code, indicator)
      case indicator
      when '='    # <%= %>
        src << " _out << " << escaped_expr(code) << ";"
      when '=='   # <%== %>
        super
      when '==='  # <%=== %>
        PrivateHelper.report_code(code, src)
      else
        # nothing
      end
    end
  
  end


  ##
  ## sanitize expression (<%= ... %>)
  ##
  class XmlEruby < EscapedEruby

    protected

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

  end  # end of class XmlEruby


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


  ##
  ## optimized Eruby class, which is faster than FastEruby class.
  ##
  ## this class runs faster but is less extensible than Eruby class.
  ## notice that this class can't import any Enhancer.
  ##
  class OptimizedEruby < Eruby

    protected

    def switch_to_expr(src)
      return if @prev_is_expr
      @prev_is_expr = true
      src << ' _out'
    end

    def switch_to_stmt(src)
      return unless @prev_is_expr
      @prev_is_expr = false
      src << ';'
    end

    def initialize_src(src)
      @initialized = false
      @prev_is_expr = false
    end

    def add_src_text(src, text)
      return if text.empty?
      text.gsub!(/['\\]/, '\\\\\&')
      if @initialized
        switch_to_expr(src)
        src << " << '" << text << "'"
      else
        src << "_out = '" << text << "';"
        @initialized = true
      end
    end

    def expr_code(code)
      return "(#{code}).to_s"
    end

    def add_src_expr(src, code, indicator)
      unless @initialized
        src << "_out = ''"
	@initialized = true
      end
      #@initialized ||= ((src << "_out = ''") && true)
      switch_to_expr(src)
      src << ' << (' << code << ').to_s'
    end

    def add_src_code(src, code)
      switch_to_stmt(src) if @initialized
      src << code << ";"
    end

    def finalize_src(src)
      src << "\n_out\n" if @initialized
    end

  end  # end of class OptimizedEruby


  ##
  ## abstract base class to escape expression (<%= ... %>)
  ##
  class OptimizedEscapedEruby < OptimizedEruby

    protected

    ## abstract method
    def escaped_expr(code)
      raise NotImplementedError.new("#{self.class.name}#escaped_expr() is not implemented.")
    end

    def add_src_expr(src, code, indicator)
      case indicator
      when '='    # <%= %>
        unless @initialized
          src << "_out = ''"
          @initialized = true
        end
	#@initialized ||= ((src << "_out = ''") && true)
        switch_to_expr(src)
        src << " << " << escaped_expr(code)
      when '=='   # <%== %>
        super
      when '==='  # <%=== %>
        switch_to_stmt(src) unless @initialized
	PrivateHelper.report_code(code, src)
      else
        # nothing
      end
    end

  end


  ##
  ## optimized XmlEruby class, which is faster than FastXmlEruby
  ##
  ## this class runs faster but is less extensible than Eruby class.
  ## notice that this class can't import any Enhancer.
  ##
  class OptimizedXmlEruby < OptimizedEscapedEruby

    protected

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

  end  # end of class OptimizedXmlEruby


end


if __FILE__ == $0

  list = ['<aaa>', 'b&b', '"ccc"']
  input = <<-END
 <ul>
  <% for item in list %>
   <li><%= item %>
       <%== item %></li>
  <% end %>
 </ul>
END

  eruby = Erubis::XmlEruby.new(input)
  puts "--- source ---"
  puts eruby.src
  puts "--- result ---"
  #puts eruby.result(binding())
  puts eruby.evaluate(:list=>list)

end
