###
### $Rev$
### $Release$
### $Copyright$
###

require 'yaml'
require 'erubis'
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
  XmlEjs = XmlEjavascript


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
      options, properties = parse_argv(argv, "hvsxTtSb", "pcrfKIlaE")
      filenames = argv
      options[?h] = true if properties[:help]

      ## help, version
      if options[?h] || options[?v]
        puts version() if options[?v]
        puts usage() if options[?h]
        puts show_properties() if options[?h]
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
      unless classname
        classname = lang =~ /\Axml(.*)/ ? "XmlE#{$1}" : "E#{lang}"
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

      ## kanji code
      $KCODE = options[?K] if options[?K]

      ## read context values from yaml file
      yamlfiles = options[?f]
      if yamlfiles
        hash = {}
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
        #hash.update(context)
        context = hash
      else
        context = {}
      end

      ## properties for engine
      properties[:pattern] = options[?p] if options[?p]
      properties[:trim]    = false       if options[?T]
      properties[:preamble] = properties[:postamble] = false if options[?b]

      ## enhancers
      enhancers = []
      if options[?E]
        enhancer_name = nil
        begin
          options[?E].split(/,/).each do |shortname|
            enhancer_name = "#{shortname}Enhancer"
            enhancers << Erubis.const_get(enhancer_name)
          end
        rescue NameError
          raise CommandOptionError.new("#{enhancer_name}: no such Enhancer.")
        end
      end

      ## create engine
      engine = klass.new(nil, properties)
      enhancers.each do |enhancer|
        engine.extend(enhancer)
        engine.bipattern = properties[:bipattern] if enhancer == Erubis::BiPatternEnhancer
      end

      ## compile and execute
      val = nil
      if filenames && !filenames.empty?
        filenames.each do |filename|
          #engine = klass.load_file(filename, properties)
          engine.filename = filename
          engine.compile!(File.read(filename))
          print val if val = do_action(action, engine, context, options)
        end
      else
        #engine = klass.new(input, properties)
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
        s = engine.evaluate(context)
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
                  if lang is 'xmlxxx' then 'XmlExxx' class is used
  -c class      : class name (XmlEruby/PrintStatementEruby/...) (default Eruby)
  -E enhancer,...  : enhancer name (Escape,PercentLine,HeaderFooter,...)
  -I path       : library include path
  -K kanji      : kanji code (euc/sjis/utf8) (default none)
  -f file.yaml  : YAML file for context values (read stdin if filename is '-')
  -t            : expand tab character in YAML file
  -S            : convert mapping key from string to symbol in YAML file

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
          value = value == nil ? true : to_value(value)
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

    def to_value(str)
      case str
      when nil, "null", "nil"         ;   return nil
      when "true", "yes"              ;   return true
      when "false", "no"              ;   return false
      when /\A\d+\z/                  ;   return str.to_i
      when /\A\d+\.\d+\z/             ;   return str.to_f
      when /\/(.*)\//                 ;   return Regexp.new($1)
      when /\A'.*'\z/, /\A".*"\z/     ;   return eval(str)
      else                            ;   return str
      end
    end

    def untabify(str)
      s = ''
      str.each_line do |line|
        s << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }
      end
      return s
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
