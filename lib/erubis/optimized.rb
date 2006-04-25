##
## $Rev$
## $Release$
## $Copyright$
##


require 'erubis/eruby'


module Erubis


  ##
  ## optimized Eruby class, which is faster than FastEruby class.
  ##
  ## this class runs faster but is less extensible than Eruby class.
  ## notice that this class can't import any Enhancer.
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
  ## abstract base class to escape expression (<%= ... %>)
  ##
  class OptimizedEscapedEruby < OptimizedEruby

    protected

    ## abstract method
    def escaped_expr(code)
      raise NotImplementedError.new("#{self.class.name}#escaped_expr() is not implemented.")
    end

    def add_src_expr(src, code, indicator)
      case indicator
      when '='    # <%= %>
        unless @initialized
          src << "_out = ''"
          @initialized = true
        end
        #@initialized ||= ((src << "_out = ''") && true)
        switch_to_expr(src)
        src << " << " << escaped_expr(code)
      when '=='   # <%== %>
        super
      when '==='  # <%=== %>
        switch_to_stmt(src) unless @initialized
        PrivateHelper.report_code(code, src)
      else
        # nothing
      end
    end

  end


  ##
  ## optimized XmlEruby class, which is faster than FastXmlEruby
  ##
  ## this class runs faster but is less extensible than Eruby class.
  ## notice that this class can't import any Enhancer.
  ##
  class OptimizedXmlEruby < OptimizedEscapedEruby

    protected

    def escaped_expr(code)
      return "Erubis::XmlHelper.escape_xml(#{code})"
    end

  end  # end of class OptimizedXmlEruby


end
