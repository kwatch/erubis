##
## $Rev$
## $Release$
## $Date$
##

testdir = File.dirname(__FILE__)
libdir  = testdir == '.' ? '../lib' : File.dirname(testdir) + '/lib'
$: << testdir
$: << libdir

require 'test/unit'
#require 'test/unit/ui/console/testrunner'
require 'assert-diff'
require 'yaml'
require 'stringio'

require 'erubis'

class ErubisTest < Test::Unit::TestCase

  #str = DATA.read()
  str = File.read(__FILE__)
  str.gsub!(/.*^__END__$/m, '')

  @@ydocs = {}
  YAML.load_documents(str) do |ydoc|
    name = ydoc['name']
    raise "*** test name '#{name}' is duplicated." if @@ydocs[name]
    ydoc.each do |key, val|
      if key[-1] == ?*
        key = key.sub(/\*\z/, '')
        val = val[$target]
        ydoc[key] = val
      end
    end
    @@ydocs[name] = ydoc
    s = <<-END
      def test_#{name}
        @name    = #{name.dump}
        _test()
      end
    END
    eval s
  end

  def _test()
    ydoc = @@ydocs[@name]
    input   = ydoc['input']
    src     = ydoc['src'].gsub(/\^/, ' ')
    output  = ydoc['output'].gsub(/\^/, ' ')
    klass   = ydoc['class'] ? (eval "Erubis::#{ydoc['class']}") : Erubis::Eruby
    options = ydoc['options'] || {}
    testopt = ydoc['testopt']

    if testopt != 'load_file'
      eruby = klass.new(input, options)
    else
      filename = "tmp.#{name}.eruby"
      begin
        File.open(filename, 'w') { |f| f.write(input) }
        eruby = klass.load_file(filename, options)
      ensure
        File.unlink(filename) if test(?f, filename)
      end
    end
    assert_equal_with_diff(src, eruby.src)

    return if testopt == 'skip_output'

    context = {}
    context[:list] = ['<aaa>', 'b&b', '"ccc"']

    if testopt != 'stdout'
      actual = eruby.evaluate(context)
      assert_equal_with_diff(output, actual)
    else
      begin
        orig = $stdout
        $stdout = stringio = StringIO.new
        actual = eruby.evaluate(context)
      ensure
        $stdout = orig if orig
      end
      assert_nil(actual)
      assert_equal_with_diff(output, stringio.string)
    end
  end

end

__END__
---
name:  basic1
input: |
    <ul>
     <% for item in list %>
      <li><%= item %></li>
     <% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
##
---
name:  basic2
input: |
    <ul>
     <% i = 0
        for item in list
          i += 1
      %>
      <li><%= item %></li>
     <% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      i = 0
        for item in list
          i += 1
    ^^
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
##
---
name:  basic3
input: |
    <ul><% i = 0
        for item in list
          i += 1 %><li><%= item %></li><% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>";  i = 0
        for item in list
          i += 1 ; _out << "<li>"; _out << ( item ).to_s; _out << "</li>";  end ; _out << "\n"
    _out << "</ul>\n"
    _out
output: |
    <ul><li><aaa></li><li>b&b</li><li>"ccc"</li>
    </ul>
##
---
name:  pattern1
options:
    :pattern : '\[@ @\]'
input: |
    <ul>
     [@ for item in list @]
      <li>[@= item @]</li>
     [@ end @]
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
##
---
name:  pattern2
options:
    :pattern : '<(?:!--)?% %(?:--)?>'
input: |
    <ul>
     <!--% for item in list %-->
      <li><%= item %></li>
     <!--% end %-->
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
##
---
name:  trim1
options:
    :trim : false
input: |
    <ul>
     <% for item in list %>
      <li><%= item %></li>
     <% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
    _out << " ";  for item in list ; _out << "\n"
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
    _out << " ";  end ; _out << "\n"
    _out << "</ul>\n"
    _out
output: |
    <ul>
    ^
      <li><aaa></li>
    ^
      <li>b&b</li>
    ^
      <li>"ccc"</li>
    ^
    </ul>
##
---
name:  xml1
class: XmlEruby
input: |
    <pre>
     <% for item in list %>
      <%= item %>
      <%== item %>
     <% end %>
    </pre>
src: |
    _out = ''; _out << "<pre>\n"
      for item in list 
    _out << "  "; _out << Erubis::XmlEruby.escape( item ); _out << "\n"
    _out << "  "; _out << ( item ).to_s; _out << "\n"
      end 
    _out << "</pre>\n"
    _out
output: |
    <pre>
      &lt;aaa&gt;
      <aaa>
      b&amp;b
      b&b
      &quot;ccc&quot;
      "ccc"
    </pre>
##
---
name:  xml2
class: XmlEruby
testopt:  skip_output
input: |
    <% for item in list %>
      <%= item["var#{n}"] %>
      <%== item["var#{n}"] %>
      <%=== item["var#{n}"] %>
      <%==== item["var#{n}"] %>
    <% end %>
src: |
    _out = '';  for item in list 
    _out << "  "; _out << Erubis::XmlEruby.escape( item["var#{n}"] ); _out << "\n"
    _out << "  "; _out << ( item["var#{n}"] ).to_s; _out << "\n"
    _out << "  "; $stderr.puts("** erubis: item[\"var\#{n}\"] = #{(item["var#{n}"]).inspect}"); _out << "\n"
    _out << "  "; _out << "\n"
     end 
    _out
output: |
##
---
name:  fast1
class: FastEruby
input: |
    <table>
     <% for item in list %>
      <tr>
        <td><%= item %></td>
        <td><%== item %></td>
      </tr>
     <% end %>
    </table>
    <ul><% for item in list %><li><%= item %></li><% end %></ul>
src: |
    _out = ''; _out << "<table>\n"
      for item in list 
    _out << "  <tr>\n    <td>"
    _out << ( item ).to_s; _out << "</td>\n    <td>"
    _out << ( item ).to_s; _out << "</td>\n  </tr>\n"

      end 
    _out << "</table>\n<ul>"
     for item in list ; _out << "<li>"; _out << ( item ).to_s; _out << "</li>";  end ; _out << "</ul>\n"
    _out
output: |
    <table>
      <tr>
        <td><aaa></td>
        <td><aaa></td>
      </tr>
      <tr>
        <td>b&b</td>
        <td>b&b</td>
      </tr>
      <tr>
        <td>"ccc"</td>
        <td>"ccc"</td>
      </tr>
    </table>
    <ul><li><aaa></li><li>b&b</li><li>"ccc"</li></ul>
##
---
name:  fast2
class: FastXmlEruby
input: |
    <table>
     <% for item in list %>
      <tr>
        <td><%= item %></td>
        <td><%== item %></td>
      </tr>
     <% end %>
    </table>
    <ul><% for item in list %><li><%= item %></li><% end %></ul>
src: |
    _out = ''; _out << "<table>\n"
      for item in list 
    _out << "  <tr>\n    <td>"
    _out << Erubis::XmlEruby.escape( item ); _out << "</td>\n    <td>"
    _out << ( item ).to_s; _out << "</td>\n  </tr>\n"

      end 
    _out << "</table>\n<ul>"
     for item in list ; _out << "<li>"; _out << Erubis::XmlEruby.escape( item ); _out << "</li>";  end ; _out << "</ul>\n"
    _out
output: |
    <table>
      <tr>
        <td>&lt;aaa&gt;</td>
        <td><aaa></td>
      </tr>
      <tr>
        <td>b&amp;b</td>
        <td>b&b</td>
      </tr>
      <tr>
        <td>&quot;ccc&quot;</td>
        <td>"ccc"</td>
      </tr>
    </table>
    <ul><li>&lt;aaa&gt;</li><li>b&amp;b</li><li>&quot;ccc&quot;</li></ul>
##
---
name:  fast3
desc:  bug
class: FastEruby
input: |
    user = <%= "Foo" %>
    <% for item in list %>
      <%= item %>
    <% end %>
src: |
    _out = ''; _out << "user = "; _out << ( "Foo" ).to_s; _out << "\n"
     for item in list 
    _out << "  "; _out << ( item ).to_s; _out << "\n"
     end 
    _out
#    _out = ''; _out << "user = "; _out << ( "Foo" ).to_s; _out << "\n"
#    _out << "";  for item in list
#    _out << ""; _out << "  "; _out << ( item ).to_s; _out << "\n"
#    _out << "";  end
#    _out << ""; _out
output: |
    user = Foo
      <aaa>
      b&b
      "ccc"
##
---
name:  stdout1
class: StdoutEruby
testopt: stdout
input: |
    <ul>
     <% for item in list %>
      <li><%= item %></li>
     <% end %>
    </ul>
src: |
    _out = $stdout; _out << "<ul>\n"
      for item in list 
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    nil
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
---
name:  print1
class: PrintEruby
input: |
    <ul>
     <% for item in list %>
      <li><% print item %></li>
     <% end %>
    </ul>
src: |
    @_out = _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>";  print item ; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
---
name:  print2
class: PrintXmlEruby
input: |
    <ul>
     <% for item in list %>
      <li><% print item %></li>
     <% end %>
    </ul>
src: |
    @_out = _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>";  print item ; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li>b&b</li>
      <li>"ccc"</li>
    </ul>
---
name:  loadfile1
testopt: load_file
#input: |
#    <ul>
#     <% for item in list %>
#      <li><%= item %></li>
#     <% end %>
#    </ul>
input:
    "<ul>\r\n <% for item in list %>\r\n  <li><%= item %></li>\r\n <% end %>\r\n</ul>\r\n"
#src: |
#    _out = ''; _out << "<ul>\n"
#      for item in list
#    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
#      end
#    _out << "</ul>\n"
#    _out
src:
  "_out = ''; _out << \"<ul>\\r\\n\"\n  for item in list \r\n_out << \"  <li>\"; _out << ( item ).to_s; _out << \"</li>\\r\\n\"\n  end \r\n_out << \"</ul>\\r\\n\"\n_out\n"
#output: |
#    <ul>
#      <li><aaa></li>
#      <li>b&b</li>
#      <li>"ccc"</li>
#    </ul>
output:
    "<ul>\r\n  <li><aaa></li>\r\n  <li>b&b</li>\r\n  <li>\"ccc\"</li>\r\n</ul>\r\n"
##
---
name:  nomatch1
desc:  bug
input: |
    <ul>
      <li>foo</li>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
    _out << "  <li>foo</li>\n"
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li>foo</li>
    </ul>
##
