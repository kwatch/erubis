##
## $Rev$
## $Release$
## $Copyright$
##

require "#{File.dirname(__FILE__)}/test.rb"

require 'stringio'

require 'erubis'
require 'erubis/engine/enhanced'
require 'erubis/engine/optimized'
require 'erubis/tiny'


class ErubisTest < Test::Unit::TestCase
  extend TestEnhancer

  testdata_list = load_yaml_document(__FILE__)
  define_testmethods(testdata_list)


  def _test()
    @src.gsub!(/\^/, ' ')
    @output.gsub!(/\^/, ' ') if @output.is_a?(String)
    @klass = @class ? Erubis.const_get(@class) : Erubis::Eruby
    @options ||= {}
    @chomp.each do |target|
      case target
      when 'src'      ;  @src.chomp!
      when 'input'    ;  @input.chomp!
      when 'expected' ;  @expected.chomp!
      else
        raise "#{@name}: invalid chomp value: #{@chomp.inspect}"
      end
    end if @chomp

    if @testopt != 'load_file'
      if @klass == Erubis::TinyEruby
        eruby = @klass.new(@input)
      else
        eruby = @klass.new(@input, @options)
      end
    else
      filename = "tmp.#{@name}.eruby"
      begin
        File.open(filename, 'w') { |f| f.write(@input) }
        eruby = @klass.load_file(filename, @options)
      ensure
        File.unlink(filename) if test(?f, filename)
      end
    end
    assert_text_equal(@src, eruby.src)

    return if @testopt == 'skip_output'

    list = ['<aaa>', 'b&b', '"ccc"']
    context = @testopt == 'context' ? Erubis::Context.new : {}
    context[:list] = list

    case @testopt
    when/\Aeval\(/
      eval eruby.src
      actual = eval @testopt
      assert_text_equal(@output, actual)
    when 'stdout', 'print'
      begin
        orig = $stdout
        $stdout = stringio = StringIO.new
        actual = eruby.evaluate(context)
      ensure
        $stdout = orig
      end
      if @testopt == 'stdout'
        assert_equal("", actual)
      else
        assert_nil(actual)
      end
      assert_text_equal(@output, stringio.string)
    when 'result'
      actual = eruby.result(binding())
      assert_text_equal(@output, actual)
    else
      actual = eruby.evaluate(context)
      assert_text_equal(@output, actual)
    end
  end

end

__END__
- name:  basic1
  input: &basic1_input|
      <ul>
       <% for item in list %>
        <li><%= item %></li>
       <% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out.join
  output: &basic1_output|
      <ul>
        <li><aaa></li>
        <li>b&b</li>
        <li>"ccc"</li>
      </ul>
##
- name:  basic2
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
      _out = []; _out << '<ul>
      ';   i = 0
           for item in list
             i += 1
      ^^^
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';   end 
      ; _out << '</ul>
      ';
      _out.join
  output: *basic1_output
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  basic3
  input: |
      <ul><% i = 0
          for item in list
            i += 1 %><li><%= item %></li><% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>'; i = 0
          for item in list
            i += 1 ; _out << '<li>'; _out << ( item ).to_s; _out << '</li>'; end ; _out << '
      '; _out << '</ul>
      ';
      _out.join
  output: |
      <ul><li><aaa></li><li>b&b</li><li>"ccc"</li>
      </ul>
##
- name:  context1
  testopt:  context
  input: |
      <ul>
       <% for item in @list %>
        <li><%= item %></li>
       <% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>
      ';  for item in @list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out.join
  output: *basic1_output
##
- name:  ignore1
  input: |
      <ul>
       <%# i = 0 %>
       <% for item in list %>
        <%#
           i += 1
           color = i % 2 == 0 ? '#FFCCCC' : '#CCCCFF'
         %>
        <li>  <%#= i %>  :  <%= item %>  </li>
       <% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>
      ';
      ;  for item in list 
      ;
      
      
      
      ; _out << '  <li>  ';; _out << '  :  '; _out << ( item ).to_s; _out << '  </li>
      ';  end 
      ; _out << '</ul>
      ';
      _out.join
  output: |
      <ul>
        <li>    :  <aaa>  </li>
        <li>    :  b&b  </li>
        <li>    :  "ccc"  </li>
      </ul>
##
- name:  quotation1
  desc:  single quotation and backslash
  class: Eruby
  input: &quotation1_input|
      a = "'"
      b = "\""
      c = '\''
  src: |
      _out = []; _out << 'a = "\'"
      b = "\\""
      c = \'\\\'\'
      ';
      _out.join
  output: *quotation1_input
##
- name:  pattern1
  options:
      :pattern : '\[@ @\]'
  input: |
      <ul>
       [@ for item in list @]
        <li>[@= item @]</li>
       [@ end @]
      </ul>
  src: |
      _out = []; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out.join
  output: *basic1_output
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  pattern2
  options:
      :pattern : '<(?:!--)?% %(?:--)?>'
  input: |
      <ul>
       <!--% for item in list %-->
        <li><%= item %></li>
       <!--% end %-->
      </ul>
  src: |
      _out = []; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out.join
  output: *basic1_output
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  trim1
  options:
      :trim : false
  input: *basic1_input
#      <ul>
#       <% for item in list %>
#        <li><%= item %></li>
#       <% end %>
#      </ul>
  src: |
      _out = []; _out << '<ul>
      '; _out << ' '; for item in list ; _out << '
      '; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      '; _out << ' '; end ; _out << '
      '; _out << '</ul>
      ';
      _out.join
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
- name:  bodyonly1
  testopt:  skip_output
  options: { :preamble: no, :postamble: no }
  input: *basic1_input
  src: |4
       _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
  chomp:  [src]
  expected: null  
##
- name:  loadfile1
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
    "_out = []; _out << '<ul>\r\n';  for item in list \r\n; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>\r\n';  end \r\n; _out << '</ul>\r\n';\n_out.join\n"
  #output: |
  #    <ul>
  #      <li><aaa></li>
  #      <li>b&b</li>
  #      <li>"ccc"</li>
  #    </ul>
  output:
      "<ul>\n  <li><aaa></li>\n  <li>b&b</li>\n  <li>\"ccc\"</li>\n</ul>\n"
  #    "<ul>\r\n  <li><aaa></li>\r\n  <li>b&b</li>\r\n  <li>\"ccc\"</li>\r\n</ul>\r\n"
##
- name:  nomatch1
  desc:  bug
  input: &nomatch1|
      <ul>
        <li>foo</li>
      </ul>
  src: |
      _out = []; _out << '<ul>
        <li>foo</li>
      </ul>
      ';
      _out.join
  output: *nomatch1
##
- name:  xml1
  class: XmlEruby
  input: |
      <pre>
       <% for item in list %>
        <%= item %>
        <%== item %>
       <% end %>
      </pre>
  src: |
      _out = []; _out << '<pre>
      ';  for item in list 
      ; _out << '  '; _out << Erubis::XmlHelper.escape_xml( item ); _out << '
      '; _out << '  '; _out << ( item ).to_s; _out << '
      ';  end 
      ; _out << '</pre>
      ';
      _out.join
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
- name:  xml2
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
      _out = []; for item in list 
      ; _out << '  '; _out << Erubis::XmlHelper.escape_xml( item["var#{n}"] ); _out << '
      '; _out << '  '; _out << ( item["var#{n}"] ).to_s; _out << '
      '; _out << '  '; $stderr.puts("*** debug: item[\"var\#{n}\"]=#{(item["var#{n}"]).inspect}"); _out << '
      '; _out << '  '; _out << '
      '; end 
      ;
      _out.join
  output: |
##
- name:  printout1
  class: PrintOutEruby
  testopt:  print
  input: *basic1_input
  src: |4
       print '<ul>
      ';  for item in list 
      ; print '  <li>'; print(( item ).to_s); print '</li>
      ';  end 
      ; print '</ul>
      ';
  output: *basic1_output
##
- name:  printenabled1
  class: PrintEnabledEruby
  input: &printenabled1_input|
      <ul>
       <% for item in list %>
        <li><% print item %></li>
       <% end %>
      </ul>
  src: |
      @_out = _out = []; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; print item ; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out.join
  output: *basic1_output
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  stdout1
  class: StdoutEruby
  testopt: stdout
  input: *basic1_input
#      <ul>
#       <% for item in list %>
#        <li><%= item %></li>
#       <% end %>
#      </ul>
  src: |
      _out = $stdout; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      ''
  output: *basic1_output
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  array1
  class: ArrayEruby
  input: |
      <ul>
       <% for item in list %>
        <li><%= item %></li>
       <% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out
  output:
      - "<ul>\n"
      - "  <li>"
      - "<aaa>"
      - "</li>\n"
      - "  <li>"
      - "b&b"
      - "</li>\n"
      - "  <li>"
      - "\"ccc\""
      - "</li>\n"
      - "</ul>\n"
##
- name:  stringbuffer1
  class: StringBufferEruby
  input: *basic1_input
#      <ul>
#       <% for item in list %>
#        <li><%= item %></li>
#       <% end %>
#      </ul>
  src: |
      _out = ''; _out << '<ul>
      ';  for item in list 
      ; _out << '  <li>'; _out << ( item ).to_s; _out << '</li>
      ';  end 
      ; _out << '</ul>
      ';
      _out
  output: *basic1_output
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  simplified
  class: SimplifiedEruby
  input: |
      <ul>
       <% for item in list %>
        <li>
         <%= item %>
        </li>
       <% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>
       '; for item in list ; _out << '
        <li>
         '; _out << ( item ).to_s; _out << '
        </li>
       '; end ; _out << '
      </ul>
      ';
      _out.join
  output: |
      <ul>
      ^
        <li>
         <aaa>
        </li>
      ^
        <li>
         b&b
        </li>
      ^
        <li>
         "ccc"
        </li>
      ^
      </ul>
##
- name:  bipattern1
  class: BiPatternEruby
  #options: { :bipattern : '\[= =\]' }
  input: |
      <% for item in list %>
        <%= item %> % <%== item %>
        [= item =] = [== item =]
      <% end %>
  src: |
      _out = []; for item in list 
      ; _out << '  '; _out << ( item ).to_s; _out << ' % '; _out << Erubis::XmlHelper.escape_xml( item ); _out << '
      '; _out << '  '; _out << ( item ).to_s; _out << ' = '; _out << Erubis::XmlHelper.escape_xml( item ); _out << '
      '; end 
      ;
      _out.join
  output: |4
        <aaa> % &lt;aaa&gt;
        <aaa> = &lt;aaa&gt;
        b&b % b&amp;b
        b&b = b&amp;b
        "ccc" % &quot;ccc&quot;
        "ccc" = &quot;ccc&quot;
##
- name:  bipattern2
  class: BiPatternEruby
  options:  { :bipattern: '\$\{ \}' }
  input: |
      <% for item in list %>
        <%=item%> % <%==item%>
        ${item} = ${=item}
      <% end %>
  src: |
      _out = []; for item in list 
      ; _out << '  '; _out << (item).to_s; _out << ' % '; _out << Erubis::XmlHelper.escape_xml(item); _out << '
      '; _out << '  '; _out << (item).to_s; _out << ' = '; _out << Erubis::XmlHelper.escape_xml(item); _out << '
      '; end 
      ;
      _out.join
  output: |4
        <aaa> % &lt;aaa&gt;
        <aaa> = &lt;aaa&gt;
        b&b % b&amp;b
        b&b = b&amp;b
        "ccc" % &quot;ccc&quot;
        "ccc" = &quot;ccc&quot;
##
- name:  percentline1
  class: PercentLineEruby
  options:
  input: |
      <table>
      % for item in list
        <tr>
          <td><%= item %></td>
          <td><%== item %></td>
        </tr>
      % end
      </table>
      <pre>
      %% double percent
       % spaced percent
      </pre>
  src: |
      _out = []; _out << '<table>
      '; for item in list
      ; _out << '  <tr>
          <td>'; _out << ( item ).to_s; _out << '</td>
          <td>'; _out << Erubis::XmlHelper.escape_xml( item ); _out << '</td>
        </tr>
      '; end
      ; _out << '</table>
      <pre>
      '; _out << '% double percent
      '; _out << ' % spaced percent
      </pre>
      ';
      _out.join
  output: |
      <table>
        <tr>
          <td><aaa></td>
          <td>&lt;aaa&gt;</td>
        </tr>
        <tr>
          <td>b&b</td>
          <td>b&amp;b</td>
        </tr>
        <tr>
          <td>"ccc"</td>
          <td>&quot;ccc&quot;</td>
        </tr>
      </table>
      <pre>
      % double percent
       % spaced percent
      </pre>
##
- name:  headerfooter1
  class: HeaderFooterEruby
  options:
  testopt:  eval('ordered_list(list)')
  input: |
      <!--#header:
      def ordered_list(list)
      #-->
      <ol>
        <% for item in list %>
        <li><%==item%></li>
        <% end %>
      </ol>
      <!--#footer: end #-->
  src: |4
      
      def ordered_list(list)
      
      _out = []; _out << '<ol>
      ';   for item in list 
      ; _out << '  <li>'; _out << Erubis::XmlHelper.escape_xml(item); _out << '</li>
      ';   end 
      ; _out << '</ol>
      ';
      _out.join
       end 
  output: |
      <ol>
        <li>&lt;aaa&gt;</li>
        <li>b&amp;b</li>
        <li>&quot;ccc&quot;</li>
      </ol>
##
- name:  optimized1
  class: OptimizedEruby
  input: &optimized1_input|
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
      _out = '<table>
      ';  for item in list 
      ; _out << '  <tr>
          <td>' << ( item ).to_s << '</td>
          <td>' << Erubis::XmlHelper.escape_xml( item ) << '</td>
        </tr>
      ';  end 
      ; _out << '</table>
      <ul>'; for item in list ; _out << '<li>' << ( item ).to_s << '</li>'; end ; _out << '</ul>
      '
      _out
  output: |
      <table>
        <tr>
          <td><aaa></td>
          <td>&lt;aaa&gt;</td>
        </tr>
        <tr>
          <td>b&b</td>
          <td>b&amp;b</td>
        </tr>
        <tr>
          <td>"ccc"</td>
          <td>&quot;ccc&quot;</td>
        </tr>
      </table>
      <ul><li><aaa></li><li>b&b</li><li>"ccc"</li></ul>
##
- name:  optimized2
  class: OptimizedXmlEruby
  input: *optimized1_input
#      <table>
#       <% for item in list %>
#        <tr>
#          <td><%= item %></td>
#          <td><%== item %></td>
#        </tr>
#       <% end %>
#      </table>
#      <ul><% for item in list %><li><%= item %></li><% end %></ul>
  src: |
      _out = '<table>
      ';  for item in list 
      ; _out << '  <tr>
          <td>' << Erubis::XmlHelper.escape_xml( item ) << '</td>
          <td>' << ( item ).to_s << '</td>
        </tr>
      ';  end 
      ; _out << '</table>
      <ul>'; for item in list ; _out << '<li>' << Erubis::XmlHelper.escape_xml( item ) << '</li>'; end ; _out << '</ul>
      '
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
- name:  optimized3
  desc:  bug
  class: OptimizedEruby
  input: |
      user = <%= "Foo" %>
      <% for item in list %>
        <%= item %>
      <% end %>
  src: |
      _out = 'user = '; _out << ( "Foo" ).to_s << '
      '; for item in list 
      ; _out << '  ' << ( item ).to_s << '
      '; end 
      ;
      _out
  output: |
      user = Foo
        <aaa>
        b&b
        "ccc"
##
- name:  optimized4
  desc:  single quotation and backslash
  class: OptimizedEruby
  input: &optimized4_input|
      a = "'"
      b = "\""
      c = '\''
  src: |
      _out = 'a = "\'"
      b = "\\""
      c = \'\\\'\'
      ';
      _out
  output: *optimized4_input
##
- name:  tiny1
  class: TinyEruby
  testopt:  result
  input: |
      <ul>
       <% for item in list %>
        <li><%= item %></li>
       <% end %>
      </ul>
  src: |
      _out = []; _out << '<ul>
       '; for item in list ; _out << '
        <li>'; _out << ( item ).to_s; _out << '</li>
       '; end ; _out << '
      </ul>
      ';
      _out.join
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
