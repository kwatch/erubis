##
## usage: ruby -s test-eruby.rb -target=eruby1
##

# (setq ed::*ruby-indent-column* 2)

currdir = File.dirname(File.expand_path(__FILE__))
testdir = File.dirname(currdir) + "/test"
$: << testdir

raise "*** target is required." unless $target

require 'test/unit'
#require 'test/unit/ui/console/testrunner'
require 'assert-diff'
require 'yaml'

require $target

class ErubyTest < Test::Unit::TestCase

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
    target = ydoc['target']
    next unless target && target.include?($target)
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
    input  = ydoc['input']
    src    = ydoc['src'].gsub(/@/, ' ')
    output = ydoc['output'].gsub(/@/, ' ')
    options = ydoc['options']
    #
    require ydoc['require'] if ydoc['require']
    klass = eval(ydoc['class'] || 'Eruby')
    if options
      eruby = klass.new(input, options)
    else
      eruby = klass.new(input)
    end
    assert_equal_with_diff(src, eruby.src)
    list = ['<aaa>', 'b&b', '"ccc"']
    assert_equal_with_diff(output, eruby.result(binding()))
  end

end

__END__
---
name:  basic1
target: [ eruby1, eruby2 ]
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
    @
      <li><aaa></li>
    @
      <li>b&b</li>
    @
      <li>"ccc"</li>
    @
    </ul>
##
---
name:  basic2
target: [ eruby1, eruby2 ]
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
    _out << " ";  i = 0
        for item in list
          i += 1
      ; _out << "\n"
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
    _out << " ";  end ; _out << "\n"
    _out << "</ul>\n"
    _out
output: |
    <ul>
    @
      <li><aaa></li>
    @
      <li>b&b</li>
    @
      <li>"ccc"</li>
    @
    </ul>
##
---
name:  basic3
target: [ eruby1, eruby2, eruby3 ]
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
name:  fast1
target: [ eruby2 ]
require: fast-eruby
class:   FastEruby
input: |
    <table>
     <% for item in list %>
      <tr>
        <td><%= item %></td>
      </tr>
     <% end %>
    </table>
src: |
    _out = ''; _out << "<table>\n "; 
     for item in list ; _out << "\n  <tr>\n    <td>"; 
    
    _out << ( item ).to_s; _out << "</td>\n  </tr>\n "; 
    
     end ; _out << "\n</table>\n"; 
    
    _out
output: |
    <table>
    @
      <tr>
        <td><aaa></td>
      </tr>
    @
      <tr>
        <td>b&b</td>
      </tr>
    @
      <tr>
        <td>"ccc"</td>
      </tr>
    @
    </table>
##
---
name:  trim1
target: [ eruby3 ]
input: |
    <ul>
     <% for item in list %>
      <li>
        <%= item %>
      </li>
     <% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>\n"
    _out << "    "; _out << ( item ).to_s; _out << "\n"
    _out << "  </li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li>
        <aaa>
      </li>
      <li>
        b&b
      </li>
      <li>
        "ccc"
      </li>
    </ul>
##
---
name:  trim2
target: [ eruby3 ]
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
    @@
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
name:  escape1
target: [ eruby4 ]
input: |
    <ul>
     <% for item in list %>
      <li><%= item %></li>
      <li><%== item %></li>
     <% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li><aaa></li>
      <li><aaa></li>
      <li>b&b</li>
      <li>b&b</li>
      <li>"ccc"</li>
      <li>"ccc"</li>
    </ul>
##
---
name:  escape2
target: [ eruby4 ]
require: xml-eruby
class:  XmlEruby
input: |
    <ul>
     <% for item in list %>
      <li><%= item %></li>
      <li><%== item %></li>
     <% end %>
    </ul>
src: |
    _out = ''; _out << "<ul>\n"
      for item in list 
    _out << "  <li>"; _out << XmlEruby.escape( item ); _out << "</li>\n"
    _out << "  <li>"; _out << ( item ).to_s; _out << "</li>\n"
      end 
    _out << "</ul>\n"
    _out
output: |
    <ul>
      <li>&lt;aaa&gt;</li>
      <li><aaa></li>
      <li>b&amp;b</li>
      <li>b&b</li>
      <li>&quot;ccc&quot;</li>
      <li>"ccc"</li>
    </ul>
##
---
name:  pattern1
target: [ eruby5 ]
options: { :pattern : '<(?:!--)?% %(?:--)?>' }
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
