#!/usr/bin/env ruby

###
### CGI script to handle *.rhtml with Erubis
###
### Licsense: same as Erubis
###

require 'erubis'
include Erubis::XmlHelper

ERUBY = Erubis::Eruby   # or Erubis::EscapeEruby
@encoding = nil

## helper class to represent http error
class HttpError < Exception
  attr_accessor :status
  def initialize(status, message)
    super(message)
    @status = status
  end
end


## main
begin

  ## check environment variables
  document_root = ENV['DOCUMENT_ROOT']  or raise "ENV['DOCUMENT_ROOT'] is not set."
  request_uri   = ENV['REQUEST_URI']    or raise "ENV['REQUEST_URI'] is not set."
  ## get filepath
  basepath = request_uri.split(/\?/, 2).first
  filepath = File.join(document_root, basepath)
  filepath.gsub!(/\.html\z/, '.rhtml')  or  # expected '*.html'
    raise HttpError.new('500 Internal Error', 'invalid .htaccess configuration.')
  File.file?(filepath)  or                  # file not found
    raise HttpError.new('404 Not Found', "#{basepath}: not found.")
  basepath != ENV['SCRIPT_NAME']  or        # can't access to index.cgi
    raise HttpError.new('403 Forbidden', "#{basepath}: not accessable.")
  ## process as eRuby file
  eruby = ERUBY.load_file(filepath)         # or ERUBY.new(File.read(filepath))
  html  = eruby.result()
  ## send response
  print @encoding \
      ? "Content-Type: text/html; charset=#{@encoding}\r\n" \
      : "Content-Type: text/html\r\n"
  print "Content-Length: #{html.length}\r\n"
  print "\r\n"
  print html

rescue HttpError => ex
  ## handle http error (such as 404 Not Found)
  print "Status: #{ex.status}\r\n"
  print "Content-Type: text/html\r\n"
  print "\r\n"
  print "<h2>#{h(ex.status)}</h2>\n"
  print "<p>#{h(ex.message)}</p>"

rescue Exception => ex
  ## print exception backtrace
  print "Status: 500 Internal Server Error\r\n"
  print "Content-Type: text/html\r\n"
  print "\r\n"
  arr = ex.backtrace
  print   "<pre>\n"
  print   "<b>#{h(arr[0])}: #{h(ex.message)} (#{h(ex.class.name)})</b>\n"
  arr[1..-1].each do |item|
    print "        from #{h(item)}\n"
  end
  print   "</pre>\n"

end
