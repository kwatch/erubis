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

    def escape_xml(obj)
      str = obj.to_s.dup
      #str = obj.to_s
      #str = str.dup if obj.__id__ == str.__id__
      str.gsub!(/&/, '&amp;')
      str.gsub!(/</, '&lt;')
      str.gsub!(/>/, '&gt;')
      str.gsub!(/"/, '&quot;')   #"
      return str
    end

    alias h escape_xml
    alias html_escape escape_xml

  end


end
