##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/eruby'
require 'erubis/enhancer'


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

    def initialize_src(src)
      @initialized = false
      @prev_is_expr = false
    end

    def add_src_text(src, text)
      return if text.empty?
      text.gsub!(/['\\]/, '\\\\\&')
      if @initialized
        switch_to_expr(src)
        src << " << '" << text << "'"
      else
        src << "_out = '" << text << "';"
        @initialized = true
      end
    end

    def add_src_expr(src, code, indicator)
      unless @initialized
        src << "_out = ''"
        @initialized = true
      end
      #@initialized ||= ((src << "_out = ''") && true)
      switch_to_expr(src)
      src << ' << (' << code << ').to_s'
    end

    def add_src_code(src, code)
      switch_to_stmt(src) if @initialized
      src << code << ";"
    end

    def finalize_src(src)
      src << "\n_out\n" if @initialized
    end

  end  # end of class OptimizedEruby


  ##
  ## XmlEruby class which generates optimized code
  ##
  class OptimizedXmlEruby < OptimizedEruby
    #include EscapeEnhancer

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

    def add_src_expr(src, code, indicator)
      case indicator
      when '='    # <%= %>
        unless @initialized
          src << "_out = ''"
          @initialized = true
        end
        #unless @initialized; src << "_out = ''"; @initialized = true; end
        #@initialized ||= ((src << "_out = ''") && true)
        switch_to_expr(src)
        src << " << " << escaped_expr(code)
      when '=='   # <%== %>
        super
      when '==='  # <%=== %>
        switch_to_stmt(src) unless @initialized
        PrivateHelper.report_expr(src, code)
      else
        # nothing
      end
    end

  end  # end of class OptimizedXmlEruby


end
