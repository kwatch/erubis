##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/eperl'
require 'erubis/pi/enhancer'


module Erubis::PI


  class Eruby < Erubis::Eperl
    include Erubis::PI::Enhancer

    def initialize(*args)
      self.pi_name = 'pl'
      super(*args)
    end

  end


end
