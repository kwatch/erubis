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
##   input = <<'END'
##    <ul>
##     <% for item in @list %>
##      <li><%= item %>
##          <%== item %></li>
##     <% end %>
##    </ul>
##   END
##   list = ['<aaa>', 'b&b', '"ccc"']
##   eruby = Erubis::Eruby.new(input)
##   puts "--- source ---"
##   puts eruby.src
##   puts "--- result ---"
##   puts eruby.evaluate(:list=>list)
##   # or puts eruby.result(binding())
##
## result:
##   --- source ---
##   _out = ""; _out << " <ul>\n"
##      for item in list
##   _out << "   <li>"; _out << ( item ).to_s; _out << "\n"
##   _out << "       "; _out << Erubis::XmlEruby.escape( item ); _out << "</li>\n"
##      end
##   _out << " </ul>\n"
##   _out
##   --- result ---
##    <ul>
##      <li><aaa>
##          &lt;aaa&gt;</li>
##      <li>b&b
##          b&amp;b</li>
##      <li>"ccc"
##          &quot;ccc&quot;</li>
##    </ul>
##


require 'erubis/engine'
require 'erubis/helper'
require 'erubis/enhancer'
#require 'erubis/tiny'
require 'erubis/engine/eruby'
#require 'erubis/engine/enhanced'    # enhanced eruby engines
#require 'erubis/engine/optimized'   # generates optimized ruby code
#require 'erubis/engine/ephp'
#require 'erubis/engine/ec'
#require 'erubis/engine/ejava'
#require 'erubis/engine/escheme'
#require 'erubis/engine/eperl'
#require 'erubis/engine/ejavascript'


require 'erubis/local-setting'
