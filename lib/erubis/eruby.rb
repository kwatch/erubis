##
## $Rev$
## $Release$
## $Copyright$
##


module Erubis


  ##
  ## base exception class
  ##
  class ErubisError < StandardError
  end


  ##
  ## base class
  ##
  class Eruby

    def initialize(input, options={})
      #@input    = input
      @pattern  = options[:pattern]  || '<% %>'
      @filename = options[:filename]
      @trim     = options[:trim] != false
      @src      = compile(input)
    end
    attr_reader :src
    attr_accessor :filename

    def self.load_file(filename, options={})
      input = File.open(filename, 'rb') { |f| f.read }
      input.untaint   # is it ok?
      options[:filename] = filename
      eruby = self.new(input, options)
      return eruby
    end

    def result(binding=TOPLEVEL_BINDING)
      filename = @filename || '(erubis)'
      eval @src, binding, filename
    end

    def evaluate(_context={})
      _evalstr = ''
      _context.keys.each do |key|
        _evalstr << "#{key.to_s} = _context[#{key.inspect}]\n"
      end
      eval _evalstr
      return result(binding())
    end

    DEFAULT_REGEXP = /(.*?)(^[ \t]*)?<%(=+|\#)?(.*?)-?%>([ \t]*\r?\n)?/m

    def pattern_regexp(pattern=@pattern)
      if pattern == '<% %>'
        return DEFAULT_REGEXP
      else
        prefix, postfix = pattern.split()
        return /(.*?)(^[ \t]*)?#{prefix}(=+|\#)?(.*?)-?#{postfix}([ \t]*\r?\n)?/m
      end
    end

    def compile(input)
      src = ""
      initialize_src(src)
      regexp = pattern_regexp(@pattern)
      input.scan(regexp) do |text, head_space, indicator, code, tail_space|
        ## * when '<%= %>', do nothing
        ## * when '<% %>' or '<%# %>', delete spaces iff only spaces are around '<% %>'
        if indicator && indicator[0] == ?=
          flag_trim = false
        else
          flag_trim = @trim && head_space && tail_space
        end
        #flag_trim = @trim && !(indicator && indicator[0]==?=) && head_space && tail_space
        add_src_text(src, text)
        add_src_text(src, head_space) if !flag_trim && head_space
        if !indicator             # <% %>
          code = "#{head_space}#{code}#{tail_space}" if flag_trim
          add_src_code(src, code)
        elsif indicator[0] == ?=  # <%= %>
          add_src_expr(src, code, indicator)
        else                      # <%# %>
          n = code.count("\n")
          n += tail_space.count("\n") if tail_space
          add_src_code(src, "\n" * n)
        end
        add_src_text(src, tail_space) if !flag_trim && tail_space
      end
      rest = $' || input
      add_src_text(src, rest)
      finalize_src(src)
      return src
    end

    protected

    def initialize_src(src)
      src << "_out = '';"
    end

    def add_src_text(src, text)
      return if text.empty?
      text.gsub!(/['\\]/, '\\\\\&')   # "'" => "\\'",  '\\' => '\\\\'
      src << " _out << '" << text << "';"
    end

    def add_src_expr(src, code, indicator)
      src << ' _out << (' << code << ').to_s;'
    end

    def add_src_code(src, code)
      src << code << ';'
    end

    def finalize_src(src)
      src << "\n_out\n"
    end

  end  # end of class Eruby


end
