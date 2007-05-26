###
### $Rev$
### $Release:$
### $Copyright$
###


require 'erubis'


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
    ##      #Erubis::Helpers::RailsHelper.show_src = false             # set true for debugging
    ##
    ## 2. (optional) apply the patch for 'action_view/base.rb'
    ##
    ##      $ cd /usr/local/lib/ruby/gems/1.8/gems/actionpack-1.13.3/lib/action_view/
    ##      $ sudo patch -p1 < /tmp/erubis_2.X.X/contrib/action_view_base_rb.patch
    ##
    ## 3. restart web server.
    ##
    ## if Erubis::Helper::Rails.show_src is ture, Erubis prints converted Ruby code
    ## into log file ('log/development.log' or so). This may be useful for debug.
    ##
    module RailsHelper

      #cattr_accessor :init_properties
      @@engine_class = Erubis::Eruby
      #@@engine_class = Erubis::FastEruby

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
      @@show_src = false

      def self.show_src
        @@show_src
      end

      def self.show_src=(flag)
        @@show_src = flag
      end

    end

  end

end


method_name = 'convert_template_into_ruby_code'
unless ActionView::Base.private_instance_methods.include?(method_name) ||
       ActionView::Base.instance_methods.include?(method_name)

  require 'action_pack/version'

  module ActionView  # :nodoc:

    class Base  # :nodoc:

      private

      # convert template into ruby code
      def convert_template_into_ruby_code(template)
        ERB.new(template, nil, @@erb_trim_mode).src
      end


if ActionPack::VERSION::MINOR <= 12   ###  Rails 1.1


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

        @@template_args[render_symbol] ||= {}
        locals_keys = @@template_args[render_symbol].keys | locals
        @@template_args[render_symbol] = locals_keys.inject({}) { |h, k| h[k] = true; h }

        locals_code = ""
        locals_keys.each do |key|
          locals_code << "#{key} = local_assigns[:#{key}] if local_assigns.has_key?(:#{key})\n"
        end

        "def #{render_symbol}(local_assigns)\n#{locals_code}#{body}\nend"
      end


else    ###  Rails 1.2 or later


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

        @@template_args[render_symbol] ||= {}
        locals_keys = @@template_args[render_symbol].keys | locals
        @@template_args[render_symbol] = locals_keys.inject({}) { |h, k| h[k] = true; h }

        locals_code = ""
        locals_keys.each do |key|
          locals_code << "#{key} = local_assigns[:#{key}]\n"
        end

        "def #{render_symbol}(local_assigns)\n#{locals_code}#{body}\nend"
      end


end   ###


    end

  end

end


## set Erubis as eRuby compiler in Ruby on Rails instead of ERB
class ActionView::Base  # :nodoc:
  private
  def convert_template_into_ruby_code(template)
    #src = Erubis::Eruby.new(template).src
    klass      = Erubis::Helpers::RailsHelper.engine_class
    properties = Erubis::Helpers::RailsHelper.init_properties
    show_src   = Erubis::Helpers::RailsHelper.show_src
    src = klass.new(template, properties).src
    #src.insert(0, '_erbout = ')
    logger.debug "** Erubis: src==<<'END'\n#{src}END\n" if show_src
    src
  end
end


## make h() method faster
module ERB::Util  # :nodoc:
  ESCAPE_TABLE = { '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;', }
  def h(value)
    value.to_s.gsub(/[&<>"]/) { |s| ESCAPE_TABLE[s] }
  end
  module_function :h
end


## finish
ac = ActionController::Base.new
ac.logger.info "** Erubis #{Erubis::VERSION}"
#$stdout.puts "** Erubis #{Erubis::VERSION}"
