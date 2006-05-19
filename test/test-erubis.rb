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

    return if @testopt == 'skip_bufput'

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
        #actual = eruby.evaluate(context)
        actual = eruby.result(context)
      ensure
        $stdout = orig
      end
      if @testopt == 'stdout'
        assert_equal("", actual)
      else
        assert_nil(actual)
      end
      assert_text_equal(@output, stringio.string)
    when 'evaluate', 'context'
      actual = eruby.evaluate(context)
      assert_text_equal(@output, actual)
    when 'binding'
      actual = eruby.result(binding())
      assert_text_equal(@output, actual)
    else
      actual = eruby.result(context)
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
      _buf = []; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf.join
  output: &basic1_bufput|
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
      _buf = []; _buf << '<ul>
      ';   i = 0
           for item in list
             i += 1
      ^^^
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';   end 
       _buf << '</ul>
      ';
      _buf.join
  output: *basic1_bufput
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
      _buf = []; _buf << '<ul>'; i = 0
          for item in list
            i += 1 ; _buf << '<li>'; _buf << ( item ).to_s; _buf << '</li>'; end ; _buf << '
      '; _buf << '</ul>
      ';
      _buf.join
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
      _buf = []; _buf << '<ul>
      ';  for item in @list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf.join
  output: *basic1_bufput
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
      _buf = []; _buf << '<ul>
      ';
        for item in list 
      
      
      
      
       _buf << '  <li>  ';; _buf << '  :  '; _buf << ( item ).to_s; _buf << '  </li>
      ';  end 
       _buf << '</ul>
      ';
      _buf.join
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
      _buf = []; _buf << 'a = "\'"
      b = "\\""
      c = \'\\\'\'
      ';
      _buf.join
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
      _buf = []; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf.join
  output: *basic1_bufput
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
      _buf = []; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf.join
  output: *basic1_bufput
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
      _buf = []; _buf << '<ul>
      '; _buf << ' '; for item in list ; _buf << '
      '; _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      '; _buf << ' '; end ; _buf << '
      '; _buf << '</ul>
      ';
      _buf.join
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
  testopt:  skip_bufput
  options: { :preamble: no, :postamble: no }
  input: *basic1_input
  src: |4
       _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
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
  #    _buf = ''; _buf << "<ul>\n"
  #      for item in list
  #    _buf << "  <li>"; _buf << ( item ).to_s; _buf << "</li>\n"
  #      end
  #    _buf << "</ul>\n"
  #    _buf
  src:
    "_buf = []; _buf << '<ul>\r\n';  for item in list \r\n _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>\r\n';  end \r\n _buf << '</ul>\r\n';\n_buf.join\n"
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
      _buf = []; _buf << '<ul>
        <li>foo</li>
      </ul>
      ';
      _buf.join
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
      _buf = []; _buf << '<pre>
      ';  for item in list 
       _buf << '  '; _buf << Erubis::XmlHelper.escape_xml( item ); _buf << '
      '; _buf << '  '; _buf << ( item ).to_s; _buf << '
      ';  end 
       _buf << '</pre>
      ';
      _buf.join
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
  testopt:  skip_bufput
  input: |
      <% for item in list %>
        <%= item["var#{n}"] %>
        <%== item["var#{n}"] %>
        <%=== item["var#{n}"] %>
        <%==== item["var#{n}"] %>
      <% end %>
  src: |
      _buf = []; for item in list 
       _buf << '  '; _buf << Erubis::XmlHelper.escape_xml( item["var#{n}"] ); _buf << '
      '; _buf << '  '; _buf << ( item["var#{n}"] ).to_s; _buf << '
      '; _buf << '  '; $stderr.puts("*** debug: item[\"var\#{n}\"]=#{(item["var#{n}"]).inspect}"); _buf << '
      '; _buf << '  '; _buf << '
      '; end 
      _buf.join
  output: |
##
- name:  printout1
  class: PrintOutEruby
  testopt:  print
  input: *basic1_input
  src: |4
       print '<ul>
      ';  for item in list 
       print '  <li>'; print(( item ).to_s); print '</li>
      ';  end 
       print '</ul>
      ';
  output: *basic1_bufput
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
      @_buf = _buf = []; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; print item ; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf.join
  output: *basic1_bufput
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
      _buf = $stdout; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      ''
  output: *basic1_bufput
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
      _buf = []; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf
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
      _buf = ''; _buf << '<ul>
      ';  for item in list 
       _buf << '  <li>'; _buf << ( item ).to_s; _buf << '</li>
      ';  end 
       _buf << '</ul>
      ';
      _buf
  output: *basic1_bufput
#      <ul>
#        <li><aaa></li>
#        <li>b&b</li>
#        <li>"ccc"</li>
#      </ul>
##
- name:  notext1
  class: NoTextEruby
  input: *basic1_input
  src: |
      _buf = [];
        for item in list 
             _buf << ( item ).to_s;
        end 
      
      _buf.join
  output:  '<aaa>b&b"ccc"'
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
      _buf = []; _buf << '<ul>
       '; for item in list ; _buf << '
        <li>
         '; _buf << ( item ).to_s; _buf << '
        </li>
       '; end ; _buf << '
      </ul>
      ';
      _buf.join
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
      _buf = []; for item in list 
       _buf << '  '; _buf << ( item ).to_s; _buf << ' % '; _buf << Erubis::XmlHelper.escape_xml( item ); _buf << '
      '; _buf << '  '; _buf << ( item ).to_s; _buf << ' = '; _buf << Erubis::XmlHelper.escape_xml( item ); _buf << '
      '; end 
      _buf.join
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
      _buf = []; for item in list 
       _buf << '  '; _buf << (item).to_s; _buf << ' % '; _buf << Erubis::XmlHelper.escape_xml(item); _buf << '
      '; _buf << '  '; _buf << (item).to_s; _buf << ' = '; _buf << Erubis::XmlHelper.escape_xml(item); _buf << '
      '; end 
      _buf.join
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
      _buf = []; _buf << '<table>
      '; for item in list
       _buf << '  <tr>
          <td>'; _buf << ( item ).to_s; _buf << '</td>
          <td>'; _buf << Erubis::XmlHelper.escape_xml( item ); _buf << '</td>
        </tr>
      '; end
       _buf << '</table>
      <pre>
      '; _buf << '% double percent
      '; _buf << ' % spaced percent
      </pre>
      ';
      _buf.join
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
      
      _buf = []; _buf << '<ol>
      ';   for item in list 
       _buf << '  <li>'; _buf << Erubis::XmlHelper.escape_xml(item); _buf << '</li>
      ';   end 
       _buf << '</ol>
      ';
      _buf.join
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
      _buf = '<table>
      ';  for item in list 
       _buf << '  <tr>
          <td>' << ( item ).to_s << '</td>
          <td>' << Erubis::XmlHelper.escape_xml( item ) << '</td>
        </tr>
      ';  end 
       _buf << '</table>
      <ul>'; for item in list ; _buf << '<li>' << ( item ).to_s << '</li>'; end ; _buf << '</ul>
      '
      _buf
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
      _buf = '<table>
      ';  for item in list 
       _buf << '  <tr>
          <td>' << Erubis::XmlHelper.escape_xml( item ) << '</td>
          <td>' << ( item ).to_s << '</td>
        </tr>
      ';  end 
       _buf << '</table>
      <ul>'; for item in list ; _buf << '<li>' << Erubis::XmlHelper.escape_xml( item ) << '</li>'; end ; _buf << '</ul>
      '
      _buf
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
      _buf = 'user = '; _buf << ( "Foo" ).to_s << '
      '; for item in list 
       _buf << '  ' << ( item ).to_s << '
      '; end 

      _buf
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
      _buf = 'a = "\'"
      b = "\\""
      c = \'\\\'\'
      ';
      _buf
  output: *optimized4_input
##
- name:  tiny1
  class: TinyEruby
  testopt:  binding
  input: |
      <ul>
       <% for item in list %>
        <li><%= item %></li>
       <% end %>
      </ul>
  src: |
      _buf = []; _buf << '<ul>
       '; for item in list ; _buf << '
        <li>'; _buf << ( item ).to_s; _buf << '</li>
       '; end ; _buf << '
      </ul>
      ';
      _buf.join
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
- name:  tiny2
  class: TinyEruby
  testopt:  evaluate
  input: |
      <ul>
       <% for item in @list %>
        <li><%= item %></li>
       <% end %>
      </ul>
  src: |
      _buf = []; _buf << '<ul>
       '; for item in @list ; _buf << '
        <li>'; _buf << ( item ).to_s; _buf << '</li>
       '; end ; _buf << '
      </ul>
      ';
      _buf.join
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
