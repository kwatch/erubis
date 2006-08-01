##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/ejava'
require 'erubis/pi/enhancer'


module Erubis::PI


  class Eruby < Erubis::Ejava
    include Erubis::PI::Enhancer

    def initialize(*args)
      self.pi_name = 'java'
      super(*args)
    end

    #def escaped_expr(code)
    #  "escapeXml(#{code.strip})"
    #end

  end


end
