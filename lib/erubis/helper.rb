##
## $Rev$
## $Release:$
## $Copyright$
##


module Erubis

  ##
  ## helper for xml
  ##
  module XmlHelper

    module_function

    ESCAPE_TABLE = {
      '&' => '&amp;',
      '<' => '&lt;',
      '>' => '&gt;',
      '"' => '&quot;',
      "'" => '&#039;',
    }

    def escape_xml(value)
      value.to_s.gsub(/[&<>"]/) { |s| ESCAPE_TABLE[s] }   # or /[&<>"']/
      #value.to_s.gsub(/[&<>"]/) { ESCAPE_TABLE[$&] }
    end

    alias h escape_xml
    alias html_escape escape_xml

  end


end
