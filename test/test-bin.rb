##
## $Rev$
## $Release$
## $Date$
##

testdir = File.dirname(File.expand_path(__FILE__))
libdir  = File.dirname(testdir) + '/lib'
$: << testdir
$: << libdir

bindir  = File.dirname(testdir) + '/bin'
$script = bindir + '/erubis'
if test(?f, 'bin/erubis')
  $script = 'bin/erubis'
elsif test(?f, '../bin/erubis')
  $script = '../bin/erubis'
end


require 'test/unit'
#require 'test/unit/ui/console/testrunner'
require 'assert-text-equal'
require 'yaml'
require 'tempfile'

require 'erubis'


class BinTest < Test::Unit::TestCase

  INPUT = <<'END'
list:
<% list = ['<aaa>', 'b&b', '"ccc"']
   for item in list %>
  - <%= item %>
<% end %>
user: <%= defined?(user) ? user : "(none)" %>
END

#  SRC = <<'END'
#_out = ''; _out << "list:\n"
# list = ['<aaa>', 'b&b', '"ccc"']
#   for item in list 
#_out << "  - "; _out << ( item ).to_s; _out << "\n"
# end 
#_out << "user: "; _out << ( defined?(user) ? user : "(none)" ).to_s; _out << "\n"
#_out
#END
  SRC = <<'END'
_out = ''; _out << 'list:
'; list = ['<aaa>', 'b&b', '"ccc"']
   for item in list 
; _out << '  - '; _out << ( item ).to_s; _out << '
'; end 
; _out << 'user: '; _out << ( defined?(user) ? user : "(none)" ).to_s; _out << '
';
_out
END

  OUTPUT = <<'END'
list:
  - <aaa>
  - b&b
  - "ccc"
user: (none)
END


  def _test()
    if @filename == nil
      method = (caller[0] =~ /in `(.*)'/) && $1    #'
      @filename = "tmp.#{method}"
    end
    File.open(@filename, 'w') { |f| f.write(@input) } if @filename
    begin
      command = "ruby #{$script} #{@options} #{@filename}"
      output = `#{command}`
    ensure
      File.unlink(@filename) if @filename && test(?f, @filename)
    end
    assert_text_equal(@expected, output)
  end


  def test_version
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


  def test_source1
    @input    = INPUT
    @expected = SRC
    @options  = '-s'
    _test()
  end


  def test_source2
    @input    = INPUT
    @expected = SRC.sub(/^_out\s*\z/, '')
    @options  = '-x'
    _test()
  end


  def test_pattern1
    @input    = INPUT.gsub(/<%/, '<!--%').gsub(/%>/, '%-->')
    @expected = OUTPUT
    @options  = "-p '<!--% %-->'"
    _test()
  end


  def test_class1
    @input    = INPUT
    @expected = OUTPUT.gsub(/<aaa>/, '&lt;aaa&gt;').gsub(/b&b/, 'b&amp;b').gsub(/"ccc"/, '&quot;ccc&quot;')
    @options  = "-c XmlEruby"
    _test()
  end


  def test_notrim1
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


  def test_notrim2
    @input    = INPUT
#    @expected = <<'END'
#_out = ''; _out << "list:\n"
# list = ['<aaa>', 'b&b', '"ccc"']
#   for item in list ; _out << "\n"
#_out << "  - "; _out << ( item ).to_s; _out << "\n"
# end ; _out << "\n"
#_out << "user: "; _out << ( defined?(user) ? user : "(none)" ).to_s; _out << "\n"
#_out
#END
    @expected = <<'END'
_out = ''; _out << 'list:
'; list = ['<aaa>', 'b&b', '"ccc"']
   for item in list ; _out << '
'; _out << '  - '; _out << ( item ).to_s; _out << '
'; end ; _out << '
'; _out << 'user: '; _out << ( defined?(user) ? user : "(none)" ).to_s; _out << '
';
_out
END
    @options = "-sT"
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


  def test_yaml1
    yamlfile = "test.context1.yaml"
    @input    = INPUT
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


  def test_untabify1
    yamlfile = "test.context2.yaml"
    @input    = INPUT
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


  def test_symbolify1
    yamlfile = "test.context3.yaml"
    @input    = <<END
<% for h in list %>
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


  def test_include1
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


  def test_require1
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


end
