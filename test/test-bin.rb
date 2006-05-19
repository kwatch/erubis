##
## $Rev$
## $Release$
## $Date$
##

require  "#{File.dirname(__FILE__)}/test.rb"

bindir  = File.dirname(TESTDIR) + '/bin'
$script = bindir + '/erubis'
if test(?f, 'bin/erubis')
  $script = 'bin/erubis'
elsif test(?f, '../bin/erubis')
  $script = '../bin/erubis'
end


require 'test/unit'
require 'assert-text-equal'
require 'yaml'
require 'tempfile'

require 'erubis'
require 'erubis/main'


class StringWriter < String
  def write(arg)
    self << arg
  end
end


class BinTest < Test::Unit::TestCase

  INPUT = <<'END'
list:
<% list = ['<aaa>', 'b&b', '"ccc"']
   for item in list %>
  - <%= item %>
<% end %>
user: <%= defined?(user) ? user : "(none)" %>
END
  INPUT2 = INPUT.gsub(/\blist([^:])/, '@list\1').gsub(/\buser([^:])/, '@user\1')

#  SRC = <<'END'
#_buf = ''; _buf << "list:\n"
# list = ['<aaa>', 'b&b', '"ccc"']
#   for item in list 
#_buf << "  - "; _buf << ( item ).to_s; _buf << "\n"
# end 
#_buf << "user: "; _buf << ( defined?(user) ? user : "(none)" ).to_s; _buf << "\n"
#_buf
#END
  SRC = <<'END'
_buf = []; _buf << 'list:
'; list = ['<aaa>', 'b&b', '"ccc"']
   for item in list 
 _buf << '  - '; _buf << ( item ).to_s; _buf << '
'; end 
 _buf << 'user: '; _buf << ( defined?(user) ? user : "(none)" ).to_s; _buf << '
';
_buf.join
END
#  SRC2 = SRC.gsub(/\blist /, '@list ').gsub(/\buser /, '@user ')

  OUTPUT = <<'END'
list:
  - <aaa>
  - b&b
  - "ccc"
user: (none)
END

  ESCAPED_OUTPUT = <<'END'
list:
  - &lt;aaa&gt;
  - b&amp;b
  - &quot;ccc&quot;
user: (none)
END


  def _test()
    if $target
      name = (caller()[0] =~ /in `test_(.*?)'/) && $1
      return unless name == $target
    end
    if @filename == nil
      method = (caller[0] =~ /in `(.*)'/) && $1    #'
      @filename = "tmp.#{method}"
    end
    File.open(@filename, 'w') { |f| f.write(@input) } if @filename
    begin
      #if @options.is_a?(Array)
      #  command = "ruby #{$script} #{@options.join(' ')} #{@filename}"
      #else
      #  command = "ruby #{$script} #{@options} #{@filename}"
      #end
      #output = `#{command}`
      if @options.is_a?(Array)
        argv = @options + [ @filename ]
      else
        argv = "#{@options} #{@filename}".split
      end
      $stdout = output = StringWriter.new
      Erubis::Main.new.execute(argv)
    ensure
      $stdout = STDOUT
      File.unlink(@filename) if @filename && test(?f, @filename)
    end
    assert_text_equal(@expected, output)
  end


  def test_version    # -v
    @options = '-v'
    @expected = (("$Release: 0.0.0 $" =~ /[.\d]+/) && $&) + "\n"
    @filename = false
    _test()
  end


  def test_basic1
    @input    = INPUT
    @expected = OUTPUT
    @options  = ''
    _test()
  end


  def test_source1    # -x
    @input    = INPUT
    @expected = SRC
    @options  = '-x'
    _test()
  end


  def test_pattern1   # -p
    @input    = INPUT.gsub(/<%/, '<!--%').gsub(/%>/, '%-->')
    @expected = OUTPUT
    #@options  = "-p '<!--% %-->'"
    @options  = ["-p", "<!--% %-->"]
    _test()
  end


  def test_class1     # -c
    @input    = INPUT
    @expected = OUTPUT.gsub(/<aaa>/, '&lt;aaa&gt;').gsub(/b&b/, 'b&amp;b').gsub(/"ccc"/, '&quot;ccc&quot;')
    @options  = "-c XmlEruby"
    _test()
  end


  def test_notrim1    # -T
    @input   = INPUT
    @expected = <<'END'
list:

  - <aaa>

  - b&b

  - "ccc"

user: (none)
END
    @options = "-T"
    _test()
  end


  def test_notrim2    # -T
    @input    = INPUT
#    @expected = <<'END'
#_buf = ''; _buf << "list:\n"
# list = ['<aaa>', 'b&b', '"ccc"']
#   for item in list ; _buf << "\n"
#_buf << "  - "; _buf << ( item ).to_s; _buf << "\n"
# end ; _buf << "\n"
#_buf << "user: "; _buf << ( defined?(user) ? user : "(none)" ).to_s; _buf << "\n"
#_buf
#END
    @expected = <<'END'
_buf = []; _buf << 'list:
'; list = ['<aaa>', 'b&b', '"ccc"']
   for item in list ; _buf << '
'; _buf << '  - '; _buf << ( item ).to_s; _buf << '
'; end ; _buf << '
'; _buf << 'user: '; _buf << ( defined?(user) ? user : "(none)" ).to_s; _buf << '
';
_buf.join
END
    @options = "-xT"
    _test()
  end


  #--
  #def test_context1
  #  @input    = INPUT
  #  @expected = OUTPUT.gsub(/\(none\)/, 'Hello')
  #  @options  = '--user=Hello'
  #  _test()
  #end
  #++


  def test_yaml1      # -f
    yamlfile = "test.context1.yaml"
    @input    = INPUT2
    @expected = OUTPUT.gsub(/\(none\)/, 'Hello')
    @options  = "-f #{yamlfile}"
    #
    yaml = <<-END
    user:  Hello
    password:  world
    END
    File.open(yamlfile, 'w') { |f| f.write(yaml) }
    begin
      _test()
    ensure
      File.unlink(yamlfile) if test(?f, yamlfile)
    end
  end


  def test_untabify1  # -t
    yamlfile = "test.context2.yaml"
    @input    = INPUT2
    @expected = OUTPUT.gsub(/\(none\)/, 'Hello')
    @options  = "-tf #{yamlfile}"
    #
    yaml = <<-END
    user:	Hello
    password:	world
    END
    File.open(yamlfile, 'w') { |f| f.write(yaml) }
    begin
      _test()
    ensure
      File.unlink(yamlfile) if test(?f, yamlfile)
    end
  end


  def test_symbolify1 # -S
    yamlfile = "test.context3.yaml"
    @input    = <<END
<% for h in @list %>
<tr>
 <td><%= h[:name] %></td><td><%= h[:mail] %></td>
</tr>
<% end %>
END
    @expected = <<END
<tr>
 <td>foo</td><td>foo@mail.com</td>
</tr>
<tr>
 <td>bar</td><td>bar@mail.org</td>
</tr>
END
    @options  = "-f #{yamlfile} -S"
    #
    yaml = <<-END
list:
  - name:  foo
    mail:  foo@mail.com
  - name:  bar
    mail:  bar@mail.org
END
    File.open(yamlfile, 'w') { |f| f.write(yaml) }
    begin
      _test()
    ensure
      File.unlink(yamlfile) if test(?f, yamlfile)
    end
  end


  def test_context1   # -B
    yamlfile = "test.context4.yaml"
    #
    @input = <<'END'
user = <%= user %>
<% for item in list %>
 - <%= item %>
<% end %>
END
    @expected = <<'END'
user = World
 - aaa
 - bbb
 - ccc
END
    @options = "-f #{yamlfile} -B "
    #
    yaml = <<-END
user: World
list:
  - aaa
  - bbb
  - ccc
END
    File.open(yamlfile, 'w') { |f| f.write(yaml) }
    begin
      _test()
    ensure
      File.unlink(yamlfile) if test(?f, yamlfile)
    end
  end


  def test_include1   # -I
    dir = 'foo'
    lib = 'bar'
    Dir.mkdir dir unless test(?d, dir)
    filename = "#{dir}/#{lib}.rb"
    File.open(filename, 'w') do |f|
      f.write <<-'END'
        def escape(str)
          return "<#{str.upcase}>"
        end
      END
    end
    #
    @input    = "<% require '#{lib}' %>\n" + INPUT.gsub(/<%= item %>/, '<%= escape(item) %>')
    @expected = OUTPUT.gsub(/<aaa>/, '<<AAA>>').gsub(/b\&b/, '<B&B>').gsub(/"ccc"/, '<"CCC">')
    @options  = "-I #{dir}"
    #
    begin
      _test()
    ensure
      File.unlink filename if test(?f, filename)
      Dir.rmdir dir if test(?d, dir)
    end
  end


  def test_require1   # -r
    dir = 'foo'
    lib = 'bar'
    Dir.mkdir dir unless test(?d, dir)
    filename = "#{dir}/#{lib}.rb"
    File.open(filename, 'w') do |f|
      f.write <<-'END'
        def escape(str)
          return "<#{str.upcase}>"
        end
      END
    end
    #
    @input    = INPUT.gsub(/<%= item %>/, '<%= escape(item) %>')
    @expected = OUTPUT.gsub(/<aaa>/, '<<AAA>>').gsub(/b\&b/, '<B&B>').gsub(/"ccc"/, '<"CCC">')
    @options  = "-I #{dir} -r #{lib}"
    #
    begin
      _test()
    ensure
      File.unlink filename if test(?f, filename)
      Dir.rmdir dir if test(?d, dir)
    end
  end


  def test_enhancers1 # -E
    @input   = <<END
<% list = %w[<aaa> b&b "ccc"] %>
% for item in list
 - <%= item %> : <%== item %>
 - [= item =] : [== item =]
% end
END
    @expected = <<END
 - &lt;aaa&gt; : <aaa>
 - &lt;aaa&gt; : <aaa>
 - b&amp;b : b&b
 - b&amp;b : b&b
 - &quot;ccc&quot; : "ccc"
 - &quot;ccc&quot; : "ccc"
END
    @options = "-E Escape,PercentLine,HeaderFooter,BiPattern"
    _test()
  end


  def test_bodyonly1  # -b
    @input = INPUT
    @expected = SRC.sub(/\A_buf = \[\];/,'').sub(/\n_buf.join\n\z/,'')
    @options = '-b -x'
    _test()
  end


  def test_escape1  # -e
    @input = INPUT
    @expected = SRC.gsub(/<< \((.*?)\).to_s;/, '<< Erubis::XmlHelper.escape_xml(\1);')
    @options = '-ex'
    _test()
  end


end
