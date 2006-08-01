##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/eruby'
require 'erubis/pi/enhancer'


module Erubis::PI


  class Eruby < Erubis::Eruby
    include Erubis::PI::Enhancer

    def initialize(*args)
      self.pi_name = 'rb'
      super(*args)
    end

    #def escaped_expr(code)
    #  "escapeXml(#{code.strip})"
    #end

  end


end
