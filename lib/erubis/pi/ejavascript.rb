##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/ejavascript'
require 'erubis/pi/enhancer'


module Erubis::PI


  class Eruby < Erubis::Ejavascript
    include Erubis::PI::Enhancer

    def initialize(*args)
      self.pi_name = 'js'
      super(*args)
    end

  end


end
