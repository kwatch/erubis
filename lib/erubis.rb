##
## $Rev$
## $Release$
## $Copyright$
##

##
## an implementation of eRuby
##
## example:
##   list = ['<aaa>', 'b&b', '"ccc"']
##   input = <<-END
##    <ul>
##     <% for item in list %>
##      <li><%= item %>
##          <%== item %></li>
##     <% end %>
##    </ul>
##   END
##   eruby = Erubis::XmlEruby.new(input)
##   puts "--- source ---"
##   puts eruby.src
##   puts "--- result ---"
##   puts eruby.result(binding())
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
    attr_reader :src, :filename

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

    private

    def compile(input)
      src = ""
      initialize_src(src)
      prefix, postfix = @pattern.split()
      regexp = /(.*?)(^[ \t]*)?#{prefix}(=*)(.*?)#{postfix}([ \t]*\r?\n)?/m
      input.scan(regexp) do |text, head_space, kind, code, tail_space|
        ## * when <%= %>, do nothing
        ## * when <% %>,
        ##    - if before/after string is spaces then delete those spaces
        ##    - else do nothing
        flag_trim = @trim && kind.empty? && head_space && tail_space
        add_src_text(src, text)
        add_src_text(src, head_space) if !flag_trim && head_space
        if kind.empty?   # <% %>
          code = "#{head_space}#{code}#{tail_space}" if flag_trim
          #code = "#{head_space}#{code}#\n" if flag_trim
          add_src_code(src, code)
        else             # <%=  %>
          add_src_expr(src, code, kind.length)
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
      src << "_out = ''; "
    end

    def add_src_text(src, text)
      #return if text.empty?
      text.each_line do |line|
        src << "_out << #{line.dump}" << (line[-1] == ?\n ? "\n" : "; ")
      end
    end

    def add_src_expr(src, code, length)
      src << "_out << (#{code}).to_s; "
    end

    def add_src_code(src, code)
      code.each_line { |line| src << line }
      src << "; " unless code[-1] == ?\n
    end

    def finalize_src(src)
      src << "_out\n"
    end

  end  # end of class Eruby


  ##
  ## do sanitizing of <%= %>
  ##
  class XmlEruby < Eruby

    def self.escape(obj)
      str = obj.to_s.dup
      #str = obj.to_s
      #str = str.dup if obj.__id__ == str.__id__
      str.gsub!(/&/, '&amp;')
      str.gsub!(/</, '&lt;')
      str.gsub!(/>/, '&gt;')
      str.gsub!(/"/, '&quot;')   #"
      return str
    end

    def add_src_expr(src, code, length)
      case length
      when 1   # <%= %>
        src << "_out << Erubis::XmlEruby.escape(#{code}); "
      when 2   # <%== %>
        super
      when 3   # <%=== %>
        code.strip!
        s = code.dump
        s.sub!(/\A"/, '')
        s.sub!(/"\z/, '')
        src << "$stdout.write(\"** debug: #{s} = \#{(#{code}).inspect}\"); "
      else
        # nothing
      end
    end

  end  # end of class XmlEruby


  ##
  ## make Eruby faster
  ##
  module FastEnhancer

    def add_src_text(src, text)
      return if text.empty?
      #src << "_out << #{text.dump}" << (text[-1] == ?\n ? "\n" : "; ")
      src << "_out << #{text.dump}"
      n = text.count("\n")
      src << ("\n" * n)
      src << "; " if n == 0
    end

  end


  ##
  ## use $stdout instead of string
  ##
  module StdoutEnhancer

    def initialize_src(src)
      src << "_out = $stdout; "
    end

    def finalize_src(src)
      src << "nil\n"
    end

  end


  class FastEruby < Eruby
    include FastEnhancer
  end


  class StdoutEruby < Eruby
    include StdoutEnhancer
  end


  class FastXmlEruby < XmlEruby
    include FastEnhancer
  end


  class StdoutXmlEruby < XmlEruby
    include StdoutEnhancer
  end


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
  puts eruby.result(binding())

end
