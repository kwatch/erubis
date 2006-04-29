##
## $Rev$
## $Release$
## $Copyright$
##

require "#{File.dirname(__FILE__)}/test.rb"

require 'erubis'
require 'erubis/engine/ruby'
require 'erubis/engine/php'
require 'erubis/engine/c'
require 'erubis/engine/java'
require 'erubis/engine/scheme'
require 'erubis/engine/perl'


class EnginesTest < Test::Unit::TestCase
  extend TestEnhancer

  #load_yaml_documents(__FILE__)
  testdata_list = load_yaml_document(__FILE__)
  define_testmethods(testdata_list)

  def _test()
    klass = Erubis.const_get(@class)
    engine = klass.new(@input, @options || {})
    actual = engine.src
    assert_text_equal(@expected, actual)
  end

end

__END__
- name:  ruby1
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
      _out = []; _out << '<table>
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
      _out.join
##
- name:  php1
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
- name:  c1
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
      #line 1 "foo.html"
        fputs("<table>\n"
              " <tbody>\n", stdout);
        for (i = 0; i < list; i++) { 
        fputs("  <tr>\n"
              "   <td>", stdout); fprintf(stdout, "%d", i); fputs("</td>\n"
              "   <td>", stdout); fprintf(stdout, "%s", escape(list[i])); fputs("</td>\n"
              "  </tr>\n", stdout);
        } 
        fputs(" </tbody>\n"
              "</table>\n", stdout);
         fprintf(stderr, "*** debug: i=" "%d", i); fputs("\n", stdout);
##
- name:  java1
  lang:  java
  class: Ejava
  options: { :out: _buf, :indent: '    ' }
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
          _buf.append("<table>\n"
                    + " <tbody>\n");
           
          int i = 0;
          for (Iterator it = list.iterator(); it.hasNext(); ) {
              String s = (String)it.next();
              i++;
             
          _buf.append("  <tr class=\""); _buf.append(i%2==0 ? "even" : "odd"); _buf.append("\">\n"
                    + "   <td>"); _buf.append(i); _buf.append("</td>\n"
                    + "   <td>"); _buf.append(escape(s)); _buf.append("</td>\n"
                    + "  </tr>\n");
           
          }
          
          _buf.append(" <tbody>\n"
                    + "</table>\n");
           System.err.println("*** debug: i="+(i)); _buf.append("\n");
##
- name:  scheme1
  lang:  scheme
  class: Escheme
  options:
  input: &scheme1_input|
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
         <td><%== item %></td>
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
      (let ((_out '())) (define (_add x) (set! _out (cons x _out)))  (let ((i 0)) 
      (_add "<table>
       <tbody>
      ")
        (for-each
         (lambda (item)
           (set! i (+ i 1))
      
      (_add "  <tr>
         <td>")(_add i)(_add "</td>
         <td>")(_add (escape item))(_add "</td>
        </tr>
      ")
          ); lambda end
         list); for-each end
      
      (_add " </tbody>
      </table>
      ")(display "*** debug: i=")(display i)(display "\n")(_add "
      ") ); let end 
        (reverse _out))
  
##
- name:  scheme2
  lang:  scheme
  class: Escheme
  options: { :func: 'display' }
  input: *scheme1_input
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
         <td>")(display (escape item))(display "</td>
        </tr>
      ")
          ); lambda end
         list); for-each end
      
      (display " </tbody>
      </table>
      ")(display "*** debug: i=")(display i)(display "\n")(display "
      ") ); let end 
##
- name:  perl1
  lang:  perl
  class: Eperl
  options:
  input: |
      <%
         my $user = 'Erubis';
         my @list = ('<aaa>', 'b&b', '"ccc"');
      %>
      <p>Hello <%= $user %>!</p>
      <table>
        <tbody>
          <% $i = 0; %>
          <% for $item (@list) { %>
          <tr bgcolor=<%= ++$i % 2 == 0 ? '#FFCCCC' : '#CCCCFF' %>">
            <td><%= $i %></td>
            <td><%== $item %></td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <%=== $i %>
  expected: |4
      
         my $user = 'Erubis';
         my @list = ('<aaa>', 'b&b', '"ccc"');
      
      print('<p>Hello '); print($user); print('!</p>
      <table>
        <tbody>
      ');      $i = 0; 
           for $item (@list) { 
      print('    <tr bgcolor='); print(++$i % 2 == 0 ? '#FFCCCC' : '#CCCCFF'); print('">
            <td>'); print($i); print('</td>
            <td>'); print(escape($item)); print('</td>
          </tr>
      ');      } 
      print('  </tbody>
      </table>
      '); print('*** debug: $i=', $i, "\n");print('
      '); 
