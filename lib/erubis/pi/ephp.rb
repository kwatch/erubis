##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/ephp'
require 'erubis/pi/enhancer'


module Erubis::PI


  class Eruby < Erubis::Ephp
    include Erubis::PI::Enhancer

    def initialize(*args)
      self.pi_name = 'php'
      super(*args)
    end

  end


end
