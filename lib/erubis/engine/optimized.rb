##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/engine/ruby'


module Erubis


  ##
  ## Eruby class which generates optimized code
  ##
  class OptimizedEruby < Eruby

    protected

    def switch_to_expr(src)
      return if @prev_is_expr
      @prev_is_expr = true
      src << ' _out'
    end

    def switch_to_stmt(src)
      return unless @prev_is_expr
      @prev_is_expr = false
      src << ';'
    end

    def init_src(src)
      @initialized = false
      @prev_is_expr = false
    end

    def add_text(src, text)
      return if text.empty?
      if @initialized
        switch_to_expr(src)
        src << " << '" << escape_text(text) << "'"
      else
        src << "_out = '" << escape_text(text) << "';"
        @initialized = true
      end
    end

    def add_expr_literal(src, code)
      unless @initialized; src << "_out = ''"; @initialized = true; end
      switch_to_expr(src)
      src << " << (" << code << ").to_s"
    end

    def add_expr_escaped(src, code)
      unless @initialized; src << "_out = ''"; @initialized = true; end
      switch_to_expr(src)
      src << " << " << escaped_expr(code)
    end

    def add_stmt(src, code)
      switch_to_stmt(src) if @initialized
      super
    end

    def finish_src(src)
      super if @initialized
    end

  end  # end of class OptimizedEruby


  ##
  ## XmlEruby class which generates optimized code
  ##
  class OptimizedXmlEruby < OptimizedEruby
    include EscapeEnhancer

    def add_expr_debug(src, code)
      switch_to_stmt(src) if indicator == '===' && !@initialized
      super
    end

  end  # end of class OptimizedXmlEruby


end
