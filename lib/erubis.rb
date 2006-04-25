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
end


require 'erubis/eruby'
require 'erubis/enhancer'
require 'erubis/optimized'
