##
## $Rev$
## $Release$
## $Copyright$
##

require 'erubis/enhancer'
require 'erubis/engine/ruby'


module Erubis


  ## (obsolete)
  class FastEruby < Eruby
    include FastEnhancer
  end


  class StdoutEruby < Eruby
    include StdoutEnhancer
  end


  class PrintStatementEruby < Eruby
    include PrintStatementEnhancer
  end


  class PrintEnabledEruby < Eruby
    include PrintEnabledEnhancer
  end


  class ArrayEruby < Eruby
    include ArrayEnhancer
  end


  #--
  #class ArrayBufferEruby < Eruby
  #  include ArrayBufferEnhancer
  #end
  #++


  class StringBufferEruby < Eruby
    include StringBufferEnhancer
  end


  class SimplifiedEruby < Eruby
    include SimplifiedEnhancer
  end


  class StdoutSimplifiedEruby < Eruby
    include StdoutEnhancer
    include SimplifiedEnhancer
  end


  class BiPatternEruby < Eruby
    include BiPatternEnhancer
  end


  class PercentLineEruby < Eruby
    include PercentLineEnhancer
  end


  class HeaderFooterEruby < Eruby
    include HeaderFooterEnhancer
  end


  ## (obsolete)
  class FastXmlEruby < Eruby
    include FastEnhancer
    include EscapeEnhancer
  end


  class StdoutXmlEruby < Eruby
    include StdoutEnhancer
    include EscapeEnhancer
  end


  class PrintStatementXmlEruby < Eruby
    include PrintStatementEnhancer
    include EscapeEnhancer
  end


  class PrintEnabledXmlEruby < Eruby
    include PrintEnabledEnhancer
    include EscapeEnhancer
  end


  class ArrayXmlEruby < Eruby
    include ArrayEnhancer
    include EscapeEnhancer
  end


  #--
  #class ArrayBufferXmlEruby < Eruby
  #  include ArrayBufferEnhancer
  #  include EscapeEnhancer
  #end
  #++


  class StrinBufferXmlEruby < Eruby
    include StringBufferEnhancer
    include EscapeEnhancer
  end


  class SimplifiedXmlEruby < Eruby
    include SimplifiedEnhancer
    include EscapeEnhancer
  end


  class StdoutSimplifiedXmlEruby < Eruby
    include StdoutEnhancer
    include SimplifiedEnhancer
    include EscapeEnhancer
  end


  class BiPatternXmlEruby < Eruby
    include BiPatternEnhancer
    include EscapeEnhancer
  end


  class PercentLineXmlEruby < Eruby
    include PercentLineEnhancer
    include EscapeEnhancer
  end


  class HeaderFooterXmlEruby < Eruby
    include HeaderFooterEnhancer
    include EscapeEnhancer
  end


end
