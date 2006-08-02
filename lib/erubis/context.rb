##
## $Rev$
## $Release$
## $Copyright$
##


module Erubis


  ##
  ## context object for Engine#evaluate
  ##
  ## ex.
  ##   template = <<'END'
  ##   Hello <%= @user %>!
  ##   <% for item in @list %>
  ##    - <%= item %>
  ##   <% end %>
  ##   END
  ##
  ##   context = Erubis::Context.new(:user=>'World', :list=>['a','b','c'])
  ##   # or
  ##   # context = Erubis::Context.new
  ##   # context[:user] = 'World'
  ##   # context[:list] = ['a', 'b', 'c']
  ##
  ##   eruby = Erubis::Eruby.new(template)
  ##   print eruby.evaluate(context)
  ##
  class Context

    def initialize(hash=nil)
      hash.each do |name, value|
        self[name] = value
      end if hash
    end

    def [](key)
      return instance_variable_get("@#{key}")
    end

    def []=(key, value)
      return instance_variable_set("@#{key}", value)
    end

    def keys
      return instance_variables.collect { |name| name[1,name.length-1] }
    end

  end


end
