##
## $Rev$
## $Release:$
## $Copyright$
##

require 'erubis/error'
require 'erubis/context'


module Erubis


  ##
  ## evaluate code
  ##
  module Evaluator

    def self.supported_properties    # :nodoc:
      return []
    end

    attr_accessor :src, :filename

    def init_evaluator(properties)
      @filename = properties[:filename]
    end

    def result(*args)
      raise NotSupportedError.new("evaluation of code except Ruby is not supported.")
    end

    def evaluate(*args)
      raise NotSupportedError.new("evaluation of code except Ruby is not supported.")
    end

  end


  ##
  ## evaluator for Ruby
  ##
  module RubyEvaluator
    include Evaluator

    def self.supported_properties    # :nodoc:
      list = Evaluator.supported_properties
      return list
    end

    ## eval(@src) with binding object
    def result(_binding_or_hash=TOPLEVEL_BINDING)
      _arg = _binding_or_hash
      if _arg.is_a?(Hash)
        ## load _context data as local variables by eval
        eval _arg.keys.inject("") { |s, k| s << "#{k.to_s} = _arg[#{k.inspect}];" }
        _arg = binding()
      end
      return eval(@src, _arg, (@filename || '(erubis)'))
    end

    ## invoke context.instance_eval(@src)
    def evaluate(context=Context.new)
      context = Context.new(context) if context.is_a?(Hash)
      return context.instance_eval(@src, (@filename || '(erubis)'))
    end

  end


end
