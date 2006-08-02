###
### $Rev$
### $Release$
### $Copyright$
###
### = How to use Erubis in Rails
###
### 1. add the folliwng code in your 'app/controllers/application.rb'.
###      --------------------
###      require 'erubis/rails/action_view_support'
###      suffix = 'erubis'
###      ActionView::Base.register_template_handler(suffix, Erubis::Rails::ViewTemplate)
###      Erubis::Rails::ViewTemplate.engine_class = Erubis::EscapedEruby ## if you want
###      --------------------
### 2. restart web server.
### 3. change view template filename from 'file.rhtml' to 'file.erubis'.
###    (suffix '.rhtml' is not recommended because error page of Rails is
###     assumed to use ERB.)
###


require 'erubis'


module Erubis

  module Rails

    class ViewTemplate


      def initialize(view)
        @view = view
      end


      @@engine_class = Erubis::Eruby
      @@engine_instance = @@engine_class.new

      def self.engine_class
        @@engine_class
      end

      def self.engine_class=(klass)
        @@engine_class = klass
        @@engine_instance = klass.new
      end

      #cattr_accessor :engine_class


      def convert(template)
        code = @@engine_instance.convert(template)
        return code
      end


      def render(template, assigns)
        ## get ruby code
        code = convert(template)

        ## use @view as context object
        @view.__send__(:evaluate_assigns)
        #or @view.instance_eval("evaluate_assigns()")
        context = @view

        ## evaluate ruby code with context object
        if assigns && !assigns.empty?
          return _evaluate_string(code, context, assigns)
        else
          return context.instance_eval(code)
        end
      end


      def _localvar_code(_localvars)
        list = _localvars.collect { |_name| "#{_name} = _localvars[#{_name.inspect}]\n" }
        code = list.join()
        return code
      end


      def _evaluate_string(_code, _context, _localvars)
        eval(_localvar_code(_localvars))
        _context.instance_eval(_code)
      end


    end #class



    class CachedViewTemplate < ViewTemplate


      @@cache_table = {}


      def render(template, assigns)
        ## template path without suffix
        ## (how to get template path name with suffix? I can't find...)
        template_basename = @view.base_path + '/' + @view.controller.action_name

        ## cache template
        proc_obj = @@cache_table[template_basename]
        unless proc_obj
          code = convert(template)
          proc_obj = eval("proc do #{code} end")
          @@cache_table[template_basename] = proc_obj
        end

        ## use @view as context object
        @view.__send__(:evaluate_assigns)
        #or @view.instance_eval("evaluate_assigns()")
        context = @view

        ## evaluate ruby code with context object
        if assigns && !assigns.empty?
          return _evaluate_proc(proc_obj, context, assigns)
        else
          return context.instance_eval(&proc_obj)
        end
      end


      def _evaluate_proc(_proc_obj, _context, _localvars)
        eval(_localvar_code(_localvars))
        _context.instance_eval(&_proc_obj)
      end


    end #class

  end #module

end #module
