##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/eruby'


module Erubis


  ## (obsolete)
  module FastEnhancer
  end


  ##
  ## use $stdout instead of string
  ##
  module StdoutEnhancer

    def initialize_src(src)
      src << "_out = $stdout;"
    end

    def finalize_src(src)
      src << "\nnil\n"
    end

  end


  ##
  ## print function is available.
  ##
  ## Notice: use Eruby#evaluate() and don't use Eruby#result()
  ## to be enable print function.
  ##
  module PrintEnhancer

    def initialize_src(src)
      src << "@_out = _out = '';"
    end

    def print(*args)
      args.each do |arg|
        @_out << arg.to_s
      end
    end

  end


  ## (obsolete)
  class FastEruby < Eruby
    include FastEnhancer
  end


  class StdoutEruby < Eruby
    include StdoutEnhancer
  end


  class PrintEruby < Eruby
    include PrintEnhancer
  end


  ## (obsolete)
  class FastXmlEruby < XmlEruby
    include FastEnhancer
  end


  class StdoutXmlEruby < XmlEruby
    include StdoutEnhancer
  end


  class PrintXmlEruby < XmlEruby
    include PrintEnhancer
  end


end
