##
## $Rev$
## $Release$
## $Copyright$
##

testdir = File.dirname(__FILE__)
libdir  = testdir == '.' ? '../lib' : File.dirname(testdir) + '/lib'
$: << testdir
$: << libdir

require 'test/unit'
#require 'test/unit/ui/console/testrunner'
require 'assert-text-equal'
require 'yaml'
require 'stringio'
require 'testutil'

require 'erubis'
require 'erubis/lang/ruby'
require 'erubis/lang/php'
require 'erubis/lang/c'
require 'erubis/lang/java'
require 'erubis/lang/scheme'


class ErubisTest < Test::Unit::TestCase

  #load_yaml_documents(__FILE__)
  load_yaml_testdata(__FILE__)


  def _test()
    klass = Erubis.const_get(@class)
    eruby = klass.new(@input, @options || {})
    actual = eruby.src
    assert_text_equal(@expected, actual)
  end

end

__END__
---
name:  ruby1
lang:  ruby
class: Eruby
options:
input: |
    <table>
     <tbody>
      <% i = 0
         list.each_with_index do |item, i| %>
      <tr>
       <td><%= i+1 %></td>
       <td><%== list %></td>
      </tr>
     <% end %>
     </tbody>
    </table>
    <%=== i+1 %>
expected: |
    _out = ''; _out << '<table>
     <tbody>
    ';   i = 0
         list.each_with_index do |item, i| 
    ; _out << '  <tr>
       <td>'; _out << ( i+1 ).to_s; _out << '</td>
       <td>'; _out << Erubis::XmlHelper.escape_xml( list ); _out << '</td>
      </tr>
    ';  end 
    ; _out << ' </tbody>
    </table>
    '; $stderr.puts("*** debug: i+1=#{(i+1).inspect}"); _out << '
    ';
    _out
##
---
name:  php1
lang:  php
class: Ephp
options:
input: |
    <table>
     <tbody>
    <%
        $i = 0;
        foreach ($list as $item) {
	    $i++;
     %>
      <tr>
       <td><%= $i %></td>
       <td><%== $item %></td>
      </tr>
    <%
        }
     %>
     </tbody>
    </table>
    <%=== $i %>
expected: |
    <table>
     <tbody>
    <?php 
        $i = 0;
        foreach ($list as $item) {
            $i++;
     ?>
      <tr>
       <td><?php echo $i; ?></td>
       <td><?php echo htmlspecialchars($item); ?></td>
      </tr>
    <?php 
        }
     ?>
     </tbody>
    </table>
    <?php error_log('*** debug: $i='.($i), 0); ?>
##
---
name:  c1
lang:  c
class: Ec
options: { :filename: foo.html, :indent: '  ' }
input: |4
    <table>
     <tbody>
    <%  for (i = 0; i < list; i++) { %>
      <tr>
       <td><%= "%d", i %></td>
       <td><%== "%s", list[i] %></td>
      </tr>
    <%  } %>
     </tbody>
    </table>
    <%=== "%d", i %>
expected: |
    # 1 "foo.html"
      fputs("<table>\n"
            " <tbody>\n", stdout);
      for (i = 0; i < list; i++) { 
      fputs("  <tr>\n"
            "   <td>", stdout); fprintf(stdout, "%d", i); fputs("</td>\n"
            "   <td>", stdout); fprintf(stdout, "%s", list[i]); fputs("</td>\n"
            "  </tr>\n", stdout);
      } 
      fputs(" </tbody>\n"
            "</table>\n", stdout);
       fprintf(stderr, "*** debug: i=" "%d", i); fputs("\n", stdout);
##
---
name:  java1
lang:  java
class: Ejava
options: { :outclass: StringBuilder, :indent: '    ' }
input: |
    <table>
     <tbody>
    <%
        int i = 0;
        for (Iterator it = list.iterator(); it.hasNext(); ) {
            String s = (String)it.next();
            i++;
    %>
      <tr class="<%= i%2==0 ? "even" : "odd" %>">
       <td><%= i %></td>
       <td><%== s %></td>
      </tr>
    <%
        }
    %>
     <tbody>
    </table>
    <%=== i %>
expected: |4
        StringBuilder _out = new StringBuilder();
        _out.append("<table>\n"
                  + " <tbody>\n");
         
        int i = 0;
        for (Iterator it = list.iterator(); it.hasNext(); ) {
            String s = (String)it.next();
            i++;
           
        _out.append("  <tr class=\""); _out.append(i%2==0 ? "even" : "odd"); _out.append("\">\n"
                  + "   <td>"); _out.append(i); _out.append("</td>\n"
                  + "   <td>"); _out.append(s); _out.append("</td>\n"
                  + "  </tr>\n");
         
        }
        
        _out.append(" <tbody>\n"
                  + "</table>\n");
         System.err.println("*** debug: i="+(i)); _out.append("\n");
---
name:  scheme1
lang:  scheme
class: Escheme
options: { :func: 'display' }
input: |
    <% (let ((i 0)) %>
    <table>
     <tbody>
    <%
      (for-each
       (lambda (item)
         (set! i (+ i 1))
    %>
      <tr>
       <td><%= i %></td>
       <td><%= item %></td>
      </tr>
    <%
        ); lambda end
       list); for-each end
    %>
     </tbody>
    </table>
    <%=== i %>
    <% ); let end %>
expected: |4
     (let ((i 0)) 
    (display "<table>
     <tbody>
    ")
      (for-each
       (lambda (item)
         (set! i (+ i 1))
    
    (display "  <tr>
       <td>")(display i)(display "</td>
       <td>")(display item)(display "</td>
      </tr>
    ")
        ); lambda end
       list); for-each end
    
    (display " </tbody>
    </table>
    ")(display "*** debug: i=")(display i)(display "
    ") ); let end 
