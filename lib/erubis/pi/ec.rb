##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/ejava'
require 'erubis/pi/enhancer'


module Erubis::PI


  class Eruby < Erubis::Ec
    include Erubis::PI::Enhancer

    def initialize(*args)
      self.pi_name = 'c'
      super(*args)
    end

  end


end
