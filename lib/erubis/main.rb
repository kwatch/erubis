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
require 'erubis/engine/ruby'
require 'erubis/engine/php'
require 'erubis/engine/c'
require 'erubis/engine/java'
require 'erubis/engine/scheme'
require 'erubis/engine/perl'
require 'erubis/engine/javascript'


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

    def execute(argv=ARGV)
      ## parse command-line options
      options, properties = parse_argv(argv, "hvsxTtSbEB", "pcrfKIlae")
      filenames = argv
      options[?h] = true if properties[:help]

      ## help, version, enhancer list
      if options[?h] || options[?v] || options[?E]
        puts version() if options[?v]
        puts usage() if options[?h]
        puts show_properties() if options[?h]
        puts show_enhancers() if options[?E]
        return
      end

      ## include path
      options[?I].split(/,/).each do |path|
        $: << path
      end if options[?I]

      ## require library
      options[?r].split(/,/).each do |library|
        require library
      end if options[?r]

      ## action
      action = options[?a]
      action ||= 'compile' if options[?x]
      action ||= 'compile' if options[?s]

      ## lang
      lang = options[?l] || 'ruby'
      action ||= 'compile' if options[?l]

      ## class name of Eruby
      classname = options[?c]
      klass = get_classobj(classname, lang)

      ## kanji code
      $KCODE = options[?K] if options[?K]

      ## read context values from yaml file
      yamlfiles = options[?f]
      context = load_yamlfiles(yamlfiles, options)

      ## properties for engine
      properties[:pattern]  = options[?p] if options[?p]
      properties[:trim]     = false       if options[?T]
      properties[:preamble] = properties[:postamble] = false if options[?b]

      ## create engine and extend enhancers
      engine = klass.new(nil, properties)
      enhancers = get_enhancers(options[?e])
      enhancers.each do |enhancer|
        engine.extend(enhancer)
        engine.bipattern = properties[:bipattern] if enhancer == Erubis::BiPatternEnhancer
      end

      ## compile and execute
      val = nil
      if filenames && !filenames.empty?
        filenames.each do |filename|
          engine.filename = filename
          engine.compile!(File.read(filename))
          print val if val = do_action(action, engine, context, options)
        end
      else
        engine.filename = '(stdin)'
        engine.compile!($stdin.read())
        print val if val = do_action(action, engine, context, options)
      end

    end

    private

    def do_action(action, engine, context, options)
      case action
      when 'compile'
        s = engine.src
        s.sub!(/^\s*[\w]+\s*\z/, '') if options[?x]
      when nil, 'exec', 'execute'
        if options[?B]
          s = engine.result(context)
        else
          s = engine.evaluate(context)
        end
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
  -s            : script source
  -x            : script source (removed the last '_out' line)
  -T            : don't trim spaces around '<% %>'
  -b            : body only (no preamble nor postamble)
  -p pattern    : embedded pattern (default '<% %>')
  -l lang       : compile but no execute (ruby/php/c/java/scheme/perl/js)
  -c class      : class name (XmlEruby/PrintStatementEruby/...) (default Eruby)
  -e enhancer,...  : enhancer name (Escaped, PercentLine, BiPattern, ...)
  -E            : show all enhancers
  -I path       : library include path
  -K kanji      : kanji code (euc/sjis/utf8) (default none)
  -f file.yaml  : YAML file for context values (read stdin if filename is '-')
  -t            : expand tab character in YAML file
  -S            : convert mapping key from string to symbol in YAML file
  -B            : invoke result(binding()) instead of evaluate(context)

END
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
          s << ("    --%-25s : %s\n" % ["#{name}=#{default_val.inspect}", desc])
        end
      end
      s << "\n"
      return s
    end

    def show_enhancers
      s = ''
      list = []
      ObjectSpace.each_object(Module) do |m| list << m end
      list.sort_by { |m| m.name }.each do |m|
        next unless m.name =~ /\AErubis::(.*)Enhancer\z/
        name = $1
        desc = m.desc
        s << ("%-14s : %s\n" % [name, desc])
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
              raise CommandOptionError.new("-#{optchar.chr}: argument required.") unless arg
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

    def untabify(text, width=8)
      sb = ''
      text.scan(/(.*?)\t/m) do |s, |
        len = (n = s.rindex(?\n)) ? s.length - n - 1 : s.length
        sb << s << (" " * (width - len % width))
      end
      return $' ? (sb << $') : text
    end

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

    def load_yamlfiles(yamlfiles, options)
      hash = {}
      return hash unless yamlfiles
      yamlfiles.split(/,/).each do |yamlfile|
        str = yamlfile == '-' ? $stdin.read() : File.read(yamlfile)
        str = untabify(str) if options[?t]
        ydoc = YAML.load(str)
        unless ydoc.is_a?(Hash)
          raise CommandOptionError.new("#{yamlfile}: root object is not a mapping.")
        end
        convert_mapping_key_from_string_to_symbol(ydoc) if options[?S]
        hash.update(ydoc)
      end
      context = hash
      return context
    end

    def convert_mapping_key_from_string_to_symbol(ydoc)
      if ydoc.is_a?(Hash)
        ydoc.each do |key, val|
          ydoc[key.intern] = ydoc.delete(key) if key.is_a?(String)
          convert_mapping_key_from_string_to_symbol(val)
        end
      elsif ydoc.is_a?(Array)
        ydoc.each do |val|
          convert_mapping_key_from_string_to_symbol(val)
        end
      end
      return ydoc
    end

  end

end
