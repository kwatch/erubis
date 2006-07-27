###
### $Rev$
### $Release$
### $Copyright$
###

require 'yaml'
require 'erubis'
require 'erubis/tiny'
require 'erubis/engine/enhanced'
require 'erubis/engine/optimized'
require 'erubis/engine/eruby'
require 'erubis/engine/ephp'
require 'erubis/engine/ec'
require 'erubis/engine/ejava'
require 'erubis/engine/escheme'
require 'erubis/engine/eperl'
require 'erubis/engine/ejavascript'


module Erubis


  Ejs = Ejavascript
  EscapedEjs = EscapedEjavascript


  class CommandOptionError < ErubisError
  end


  ##
  ## main class of command
  ##
  ## ex.
  ##   Main.main(ARGV)
  ##
  class Main

    def self.main(argv=ARGV)
      status = 0
      begin
        Main.new.execute(ARGV)
      rescue CommandOptionError => ex
        $stderr.puts ex.message
        status = 1
      end
      exit(status)
    end

    def initialize
      @single_options = "hvxTtSbeB"
      @arg_options    = "pcrfKIlaE"
      @option_names   = {
        ?h => :help,
        ?v => :version,
        ?x => :source,
        ?T => :notrim,
        ?t => :untabify,
        ?S => :intern,
        ?b => :bodyonly,
        ?B => :binding,
        ?p => :pattern,
        ?c => :class,
        ?e => :escape,
        ?r => :requires,
        ?f => :yamlfiles,
        ?K => :kanji,
        ?I => :includes,
        ?l => :lang,
        ?a => :action,
        ?E => :enhancers,
      }
      assert unless @single_options.length + @arg_options.length == @option_names.length
      (@single_options + @arg_options).each_byte do |ch|
        assert unless @option_names.key?(ch)
      end
    end


    def execute(argv=ARGV)
      ## parse command-line options
      options, properties = parse_argv(argv, @single_options, @arg_options)
      filenames = argv
      options[?h] = true if properties[:help]
      opts = Object.new
      arr = @option_names.collect { |ch, name| "def #{name}; @#{name}; end\n" }
      opts.instance_eval arr.join
      options.each do |ch, val|
        name = @option_names[ch]
        opts.instance_variable_set("@#{name}", val)
      end

      ## help, version, enhancer list
      if opts.help || opts.version
        puts version()         if opts.version
        puts usage()           if opts.help
        puts show_properties() if opts.help
        puts show_enhancers()  if opts.help
        return
      end

      ## include path
      opts.includes.split(/,/).each do |path|
        $: << path
      end if opts.includes

      ## require library
      opts.requires.split(/,/).each do |library|
        require library
      end if opts.requires

      ## action
      action = opts.action
      action ||= 'compile' if opts.source

      ## lang
      lang = opts.lang || 'ruby'
      action ||= 'compile' if opts.lang

      ## class name of Eruby
      classname = opts.class
      klass = get_classobj(classname, lang)

      ## kanji code
      $KCODE = opts.kanji if opts.kanji

      ## read context values from yaml file
      yamlfiles = opts.yamlfiles
      context = load_yamlfiles(yamlfiles, opts)

      ## properties for engine
      properties[:pattern]  = opts.pattern if opts.pattern
      properties[:trim]     = false        if opts.notrim
      properties[:preamble] = properties[:postamble] = false if opts.bodyonly

      ## create engine and extend enhancers
      engine = klass.new(nil, properties)
      enhancers = get_enhancers(opts.enhancers)
      enhancers.push(Erubis::EscapeEnhancer) if opts.escape
      enhancers.each do |enhancer|
        engine.extend(enhancer)
        engine.bipattern = properties[:bipattern] if enhancer == Erubis::BiPatternEnhancer
      end

      ## compile and execute
      val = nil
      if filenames && !filenames.empty?
        filenames.each do |filename|
          test(?f, filename)  or raise CommandOptionError.new("#{filename}: file not found.")
          engine.filename = filename
          engine.compile!(File.read(filename))
          print val if val = do_action(action, engine, context, opts)
        end
      else
        engine.filename = '(stdin)'
        engine.compile!($stdin.read())
        print val if val = do_action(action, engine, context, opts)
      end

    end

    private

    def do_action(action, engine, context, opts)
      case action
      when 'compile'
        s = engine.src
      when nil, 'exec', 'execute'
        s = opts.binding ? engine.result(context) : engine.evaluate(context)
      else
        raise "*** internal error"
      end
      return s
    end

    def usage
      command = File.basename($0)
      s = <<END
erubis - embedded program compiler for multi-language
Usage: #{command} [..options..] [file ...]
  -h, --help    : help
  -v            : version
  -x            : compiled code
  -T            : don't trim spaces around '<% %>'
  -b            : body only (no preamble nor postamble)
  -e            : escape (equal to '--E Escape')
  -p pattern    : embedded pattern (default '<% %>')
  -l lang       : compile but no execute (ruby/php/c/java/scheme/perl/js)
  -E enhancer,... : enhancer name (Escape, PercentLine, BiPattern, ...)
  -I path       : library include path
  -K kanji      : kanji code (euc/sjis/utf8) (default none)
  -f file.yaml  : YAML file for context values (read stdin if filename is '-')
  -t            : expand tab character in YAML file
  -S            : convert mapping key from string to symbol in YAML file
  -B            : invoke 'result(binding)' instead of 'evaluate(context)'

END
      #'
      #  -c class      : class name (XmlEruby/PercentLineEruby/...) (default Eruby)
      #  -r library    : require library
      #  -a            : action (compile/execute)
      return s
    end

    def show_properties
      s = "supported properties:\n"
      %w[(common) ruby php c java scheme perl javascript].each do |lang|
        list = Erubis::Engine.supported_properties
        if lang != '(common)'
          klass = Erubis.const_get("E#{lang}")
          list = klass.supported_properties - list
        end
        s << "  * #{lang}\n"
        list.each do |name, default_val, desc|
          s << ("     --%-23s : %s\n" % ["#{name}=#{default_val.inspect}", desc])
        end
      end
      s << "\n"
      return s
    end

    def show_enhancers
      s = "enhancers:\n"
      list = []
      ObjectSpace.each_object(Module) do |m| list << m end
      list.sort_by { |m| m.name }.each do |m|
        next unless m.name =~ /\AErubis::(.*)Enhancer\z/
        name = $1
        desc = m.desc
        s << ("  %-13s : %s\n" % [name, desc])
      end
      return s
    end

    def version
      release = ('$Release: 0.0.0 $' =~ /([.\d]+)/) && $1
      return release
    end

    def parse_argv(argv, arg_none='', arg_required='', arg_optional='')
      options = {}
      context = {}
      while argv[0] && argv[0][0] == ?-
        optstr = argv.shift
        optstr = optstr[1, optstr.length-1]
        #
        if optstr[0] == ?-    # context
          unless optstr =~ /\A\-([-\w]+)(?:=(.*))?/
            raise CommandOptionError.new("-#{optstr}: invalid context value.")
          end
          name = $1;  value = $2
          name  = name.gsub(/-/, '_').intern
          #value = value.nil? ? true : YAML.load(value)   # error, why?
          value = value.nil? ? true : YAML.load("---\n#{value}\n")
          context[name] = value
          #
        else                  # options
          while optstr && !optstr.empty?
            optchar = optstr[0]
            optstr[0,1] = ""
            if arg_none.include?(optchar)
              options[optchar] = true
            elsif arg_required.include?(optchar)
              arg = optstr.empty? ? argv.shift : optstr
              unless arg
                mesg = "-#{optchar.chr}: #{@option_args[optchar]} required."
                raise CommandOptionError.new(mesg)
              end
              options[optchar] = arg
              optstr = nil
            elsif arg_optional.include?(optchar)
              arg = optstr.empty? ? true : optstr
              options[optchar] = arg
              optstr = nil
            else
              raise CommandOptionError.new("-#{optchar.chr}: unknown option.")
            end
          end
        end
        #
      end  # end of while

      return options, context
    end


    def untabify(str, width=8)
      list = str.split(/\t/)
      last = list.pop
      buf = []
      list.each do |s|
        column = (n = s.rindex(?\n)) ? s.length - n - 1 : s.length
        n = width - (column % width)
        buf << s << (" " * n)
      end
      buf << last
      return buf.join
    end
    #--
    #def untabify(str, width=8)
    #  sb = ''
    #  str.scan(/(.*?)\t/m) do |s, |
    #    len = (n = s.rindex(?\n)) ? s.length - n - 1 : s.length
    #    sb << s << (" " * (width - len % width))
    #  end
    #  return $' ? (sb << $') : str
    #end
    #++


    def get_classobj(classname, lang)
      unless classname
        classname = lang =~ /\Axml(.*)/ ? "EscapedE#{$1}" : "E#{lang}"
      end
      begin
        klass = Erubis.const_get(classname)
      rescue NameError
        klass = nil
      end
      unless klass
        if lang
          msg = "-l #{lang}: invalid language name (class Erubis::#{classname} not found)."
        else
          msg = "-c #{classname}: invalid class name."
        end
        raise CommandOptionError.new(msg)
      end
      return klass
    end

    def get_enhancers(enhancer_names)
      return [] unless enhancer_names
      enhancers = []
      shortname = nil
      begin
        enhancer_names.split(/,/).each do |shortname|
          enhancers << Erubis.const_get("#{shortname}Enhancer")
        end
      rescue NameError
        raise CommandOptionError.new("#{shortname}: no such Enhancer (try '-E' to show all enhancers).")
      end
      return enhancers
    end

    def load_yamlfiles(yamlfiles, opts)
      hash = {}
      return hash unless yamlfiles
      yamlfiles.split(/,/).each do |yamlfile|
        if yamlfile == '-'
          str = $stdin.read()
        else
          test(?f, yamlfile)  or raise CommandOptionError.new("#{yamlfile}: file not found.")
          str = File.read(yamlfile)
        end
        str = yamlfile == '-' ? $stdin.read() : File.read(yamlfile)
        str = untabify(str) if opts.untabify
        ydoc = YAML.load(str)
        unless ydoc.is_a?(Hash)
          raise CommandOptionError.new("#{yamlfile}: root object is not a mapping.")
        end
        intern_hash_keys(ydoc) if opts.intern
        hash.update(ydoc)
      end
      context = hash
      return context
    end

    def intern_hash_keys(obj, done={})
      return if done.key?(obj.__id__)
      case obj
      when Hash
        done[obj.__id__] = obj
        obj.keys.each do |key|
          obj[key.intern] = obj.delete(key) if key.is_a?(String)
        end
        obj.values.each do |val|
          intern_hash_keys(val, done) if val.is_a?(Hash) || val.is_a?(Array)
        end
      when Array
        done[obj.__id__] = obj
        obj.each do |val|
          intern_hash_keys(val, done) if val.is_a?(Hash) || val.is_a?(Array)
        end
      end
    end

  end

end
