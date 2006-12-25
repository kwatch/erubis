##
## $Rev$
## $Release$
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

    def escape_xml(obj)
      #table = ESCAPE_TABLE
      #obj.to_s.gsub(/[&<>"]/) { |s| table[s] }    # or /[&<>"']/
      obj.to_s.gsub(/[&<>"]/) { |s| ESCAPE_TABLE[s] }   # or /[&<>"']/
      #obj.to_s.gsub(/[&<>"]/) { ESCAPE_TABLE[$&] }
    end

    #--
    #def escape_xml(obj)
    #  str = obj.to_s.dup
    #  #str = obj.to_s
    #  #str = str.dup if obj.__id__ == str.__id__
    #  str.gsub!(/&/, '&amp;')
    #  str.gsub!(/</, '&lt;')
    #  str.gsub!(/>/, '&gt;')
    #  str.gsub!(/"/, '&quot;')
    #  str.gsub!(/'/, '&#039;')
    #  return str
    #end
    #++

    alias h escape_xml
    alias html_escape escape_xml

  end


end
