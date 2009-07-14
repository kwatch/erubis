##
## $Release:$
## $Copyright$
##

module Erubis


  ##
  ## base error class
  ##
  class ErubisError < StandardError
  end


  ##
  ## raised when method or function is not supported
  ##
  class NotSupportedError < ErubisError
  end


end
