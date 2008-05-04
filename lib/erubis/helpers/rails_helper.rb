###
### $Rev$
### $Release:$
### $Copyright$
###


require 'erubis'
require 'erubis/preprocessing'


module Erubis

  class Eruby
    include ErboutEnhancer      # will generate '_erbout = _buf = ""; '
  end

  class FastEruby
    include ErboutEnhancer      # will generate '_erbout = _buf = ""; '
  end

  module Helpers

    ##
    ## helper module for Ruby on Rails
    ##
    ## howto:
    ##
    ## 1. add the folliwng code in your 'config/environment.rb'
    ##
    ##      require 'erubis/helpers/rails_helper'
    ##      #Erubis::Helpers::RailsHelper.engine_class = Erubis::Eruby # or Erubis::FastEruby
    ##      #Erubis::Helpers::RailsHelper.init_properties = {}
    ##      #Erubis::Helpers::RailsHelper.show_src = false       # set true for debugging
    ##      #Erubis::Helpers::RailsHelper.preprocessing = true   # set true to enable preprocessing
    ##
    ## 2. restart web server.
    ##
    ## if Erubis::Helper::Rails.show_src is true, Erubis prints converted Ruby code
    ## into log file ('log/development.log' or so). if false, it doesn't.
    ## if nil, Erubis prints converted Ruby code if ENV['RAILS_ENV'] == 'development'.
    ##
    module RailsHelper

      #cattr_accessor :init_properties
      @@engine_class = ::Erubis::Eruby
      #@@engine_class = ::Erubis::FastEruby
      def self.engine_class
        @@engine_class
      end
      def self.engine_class=(klass)
        @@engine_class = klass
      end

      #cattr_accessor :init_properties
      @@init_properties = {}
      def self.init_properties
        @@init_properties
      end
      def self.init_properties=(hash)
        @@init_properties = hash
      end

      #cattr_accessor :show_src
      @@show_src = nil
      def self.show_src
        @@show_src
      end
      def self.show_src=(flag)
        @@show_src = flag
      end

      #cattr_accessor :preprocessing
      @@preprocessing = false
      def self.preprocessing
        @@preprocessing
      end
      def self.preprocessing=(flag)
        @@preprocessing = flag
      end


      ## define class for backward-compatibility
      class PreprocessingEruby < Erubis::PreprocessingEruby
      end


      module TemplateConverter
        ## covert eRuby string into ruby code
        def _convert_template(template, view_obj=nil)    # :nodoc:
          #$stderr.puts "*** debug: self.class.name=#{self.class.name}"
          #                      #=> ActionView::TemplateHandlers::Erubis
          #$stderr.puts "*** debug: self.instance_variables=#{self.instance_variables.sort.inspect}"
          #                      #=> ["@view"]
          #$stderr.puts "*** debug: @view.class.name=#{@view.class.name}"
          #                      #=> ActionView::Base
          #$stderr.puts "*** debug: @view.instance_variables=#{@view.instance_variables.sort.inspect}"
          #                      #=> ["@assigns", "@assigns_added", "@controller", "@first_render", "@logger", "@template_format", "@view_paths"]
          #                      #=> =["@_cookies", "@_flash", "@_headers", "@_params", "@_request", "@_response", "@_session", "@action_name", "@assigns", "@assigns_added", "@before_filter_chain_aborted", "@content_for_layout", "@controller", "@first_render", "@ignore_missing_templates", "@logger", "@request_origin", "@stocks", "@template", "@template_class", "@template_format", "@url", "@variables_added", "@view_paths"]
          #$stderr.puts "*** debug: self.methods=#{(self.methods.sort - Object.new.methods).inspect}"
          #                      #=> ["_convert_template", "compile", "render"]
          ##$stderr.puts "*** debug: self.methods=#{(self.methods.sort).inspect}"
          #$stderr.puts "*** debug: @views.methods=#{(@views.methods.sort - Object.new.methods).inspect}"
          ##$stderr.puts "*** debug: @views.methods=#{(@views.methods.sort).inspect}"
          #                      #=> ["&", "^", "to_f", "to_i", "|"]
          #$stderr.puts "*** debug: @first_render.class.name=#{@first_render.class.name.inspect}"
          #$stderr.puts "*** debug: @view.controller.instance_variables=#{@view.controller.instance_variables.inspect}"
          #                      #=> ["@stocks", "@_headers", "@template", "@_params", "@performed_redirect", "@before_filter_chain_aborted", "@_flash", "@assigns", "@_session", "@request_origin", "@_request", "@variables_added", "@_response", "@performed_render", "@url", "@action_name", "@_cookies"]
          #                      #=> ["@stocks", "@_headers", "@template", "@_params", "@performed_redirect", "@before_filter_chain_aborted", "@_flash", "@assigns", "@_session", "@request_origin", "@_request", "@variables_added", "@_response", "@performed_render", "@url", "@action_name", "@_cookies"]
          #$stderr.puts "*** debug: @view.controller.methods=#{@view.controller.methods.sort.inspect}"
          #$stderr.puts "*** debug: self.object_id=#{self.object_id}"
          #$stderr.puts "*** debug: @view.controller.instance_variable_get('@template').object_id=#{@view.controller.instance_variable_get('@template').object_id}"
          #$stderr.puts "*** debug: @view.controller.instance_variable_get('@template').class=#{@view.controller.instance_variable_get('@template').class}"


          #src = ::Erubis::Eruby.new(template).src
          klass      = ::Erubis::Helpers::RailsHelper.engine_class
          properties = ::Erubis::Helpers::RailsHelper.init_properties
          show_src   = ::Erubis::Helpers::RailsHelper.show_src
          show_src = ENV['RAILS_ENV'] == 'development' if show_src.nil?
          logger = view_obj ? view_obj.controller.logger : self.logger if show_src
          ## preprocessing
          if ::Erubis::Helpers::RailsHelper.preprocessing
            preprocessor = PreprocessingEruby.new(template, :escape=>true)
            #template = self.instance_eval(preprocessor.src)
            self_ = view_obj ? view_obj.controller.instance_variable_get('@template') : self
            template = preprocessor.evaluate(self_)
            logger.debug "** Erubis: preprocessed==<<'END'\n#{template}END\n" if show_src
          end
          ## convert into ruby code
          src = klass.new(template, properties).src
          #src.insert(0, '_erbout = ')
          logger.debug "** Erubis: src==<<'END'\n#{src}END\n" if show_src
          return src
        end
      end

    end

  end

end


class ActionView::Base   # :nodoc:
  include ::Erubis::Helpers::RailsHelper::TemplateConverter
  include ::Erubis::PreprocessingHelper
  private
  # convert template into ruby code
  def convert_template_into_ruby_code(template)
    #ERB.new(template, nil, @@erb_trim_mode).src
    return _convert_template(template)
  end
end


require 'action_pack/version'


if ActionPack::VERSION::MAJOR >= 2             ### Rails 2.X


  if ActionPack::VERSION::MINOR > 0 || ActionPack::VERSION::TINY >= 2   ### Rails 2.0.2 or higher

    module ActionView
      module TemplateHandlers # :nodoc:
        class Erubis < TemplateHandler
          include ::Erubis::Helpers::RailsHelper::TemplateConverter
          include ::Erubis::PreprocessingHelper
          def compile(template)
            return _convert_template(template, @view)
          end
        end
      end
      Base.class_eval do
        register_default_template_handler :erb, TemplateHandlers::Erubis
        register_template_handler :rhtml, TemplateHandlers::Erubis
      end
    end

  else                                         ### Rails 2.0.0 or 2.0.1

    class ActionView::Base   # :nodoc:
      private
      # Method to create the source code for a given template.
      def create_template_source(extension, template, render_symbol, locals)
        if template_requires_setup?(extension)
          body = case extension.to_sym
            when :rxml, :builder
              content_type_handler = (controller.respond_to?(:response) ? "controller.response" : "controller")
              "#{content_type_handler}.content_type ||= Mime::XML\n" +
              "xml = Builder::XmlMarkup.new(:indent => 2)\n" +
              template +
              "\nxml.target!\n"
            when :rjs
              "controller.response.content_type ||= Mime::JS\n" +
              "update_page do |page|\n#{template}\nend"
          end
        else
          #body = ERB.new(template, nil, @@erb_trim_mode).src
          body = convert_template_into_ruby_code(template)
        end
        #
        @@template_args[render_symbol] ||= {}
        locals_keys = @@template_args[render_symbol].keys | locals
        @@template_args[render_symbol] = locals_keys.inject({}) { |h, k| h[k] = true; h }
        #
        locals_code = ""
        locals_keys.each do |key|
          locals_code << "#{key} = local_assigns[:#{key}]\n"
        end
        #
        "def #{render_symbol}(local_assigns)\n#{locals_code}#{body}\nend"
      end
    end

  end #if


else                                           ###  Rails 1.X


  if ActionPack::VERSION::MINOR > 12           ###  Rails 1.2

    class ActionView::Base   # :nodoc:
      private
      # Create source code for given template
      def create_template_source(extension, template, render_symbol, locals)
        if template_requires_setup?(extension)
          body = case extension.to_sym
            when :rxml
              "controller.response.content_type ||= 'application/xml'\n" +
              "xml = Builder::XmlMarkup.new(:indent => 2)\n" +
              template
            when :rjs
              "controller.response.content_type ||= 'text/javascript'\n" +
              "update_page do |page|\n#{template}\nend"
          end
        else
          #body = ERB.new(template, nil, @@erb_trim_mode).src
          body = convert_template_into_ruby_code(template)
        end
        #
        @@template_args[render_symbol] ||= {}
        locals_keys = @@template_args[render_symbol].keys | locals
        @@template_args[render_symbol] = locals_keys.inject({}) { |h, k| h[k] = true; h }
        #
        locals_code = ""
        locals_keys.each do |key|
          locals_code << "#{key} = local_assigns[:#{key}]\n"
        end
        #
        "def #{render_symbol}(local_assigns)\n#{locals_code}#{body}\nend"
      end
    end

  else                                         ###  Rails 1.1

    class ActionView::Base   # :nodoc:
      private
      # Create source code for given template
      def create_template_source(extension, template, render_symbol, locals)
        if template_requires_setup?(extension)
          body = case extension.to_sym
            when :rxml
              "xml = Builder::XmlMarkup.new(:indent => 2)\n" +
              "@controller.headers['Content-Type'] ||= 'application/xml'\n" +
              template
            when :rjs
              "@controller.headers['Content-Type'] ||= 'text/javascript'\n" +
              "update_page do |page|\n#{template}\nend"
          end
        else
          #body = ERB.new(template, nil, @@erb_trim_mode).src
          body = convert_template_into_ruby_code(template)
        end
        #
        @@template_args[render_symbol] ||= {}
        locals_keys = @@template_args[render_symbol].keys | locals
        @@template_args[render_symbol] = locals_keys.inject({}) { |h, k| h[k] = true; h }
        #
        locals_code = ""
        locals_keys.each do |key|
          locals_code << "#{key} = local_assigns[:#{key}] if local_assigns.has_key?(:#{key})\n"
        end
        #
        "def #{render_symbol}(local_assigns)\n#{locals_code}#{body}\nend"
      end
    end

  end #if

end   ###


## make h() method faster
module ERB::Util  # :nodoc:
  ESCAPE_TABLE = { '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;', }
  def h(value)
    value.to_s.gsub(/[&<>"]/) {|s| ESCAPE_TABLE[s] }
  end
  module_function :h
end


## finish
ac = ActionController::Base.new
ac.logger.info "** Erubis #{::Erubis::VERSION}"
#$stdout.puts "** Erubis #{::Erubis::VERSION}"
