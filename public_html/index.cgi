#!/usr/bin/env ruby

###
### CGI script to handle *.rhtml with Erubis
###
### Licsense: same as Erubis
###

## add directory path where Erubis installed
#$LOAD_PATH << "/home/yourname/lib/ruby"

## load Erubis
begin
  require 'erubis'
rescue LoadError => ex
  begin
    require 'rubygems'
    require 'erubis'
  rescue LoadError # => ex
    print "Status: 500 Internal Server Error\r\n"
    print "Content-Type: text/plain\r\n"
    print "\r\n"
    print "LoadError: #{ex.message}"
    exit
  end
end

## configuration
$ENCODING = nil
$LAYOUT   = '_layout.rhtml'
$ERUBIS_CLASS = Erubis::Eruby   # or Erubis::EscapeEruby


## helper class to represent http error
class HttpError < Exception
  attr_accessor :status
  def initialize(status, message)
    super(message)
    @status = status
  end
end


class ErubisHandler
  include Erubis::XmlHelper

  def initialize
    @encoding = $ENCODING
    @layout   = $LAYOUT
  end

  attr_accessor :encoding, :layout

  def handle(env)
    ## check environment variables
    document_root = env['DOCUMENT_ROOT']  or raise "ENV['DOCUMENT_ROOT'] is not set."
    request_uri   = env['REQUEST_URI']    or raise "ENV['REQUEST_URI'] is not set."
    ## get filepath
    basepath = request_uri.split(/\?/, 2).first
    filepath = basepath =~ /\A\/(~[-.\w]+)/ \
             ? File.join(File.expand_path($1), "public_html", $') \
             : File.join(document_root, basepath)
    filepath.gsub!(/\.html\z/, '.rhtml')  or  # expected '*.html'
      raise HttpError.new(500, 'invalid .htaccess configuration.')
    File.file?(filepath)  or                  # file not found
      raise HttpError.new(404, "#{basepath}: not found.")
    basepath != env['SCRIPT_NAME']  or        # can't access to index.cgi
      raise HttpError.new(403, "#{basepath}: not accessable.")
    ## process as eRuby file
    #eruby = $ERUBIS_CLASS.new(File.read(filepath))  # not create cache file (slower)
    eruby = $ERUBIS_CLASS.load_file(filepath)        # create cache file (faster)
    html  = eruby.evaluate(self)
    ## use layout template
    if @layout && File.file?(@layout)
      @content = html
      html = $ERUBIS_CLASS.load_file(@layout).evaluate(self)
    end
    return html
  end

end


class ErubisApplication
  include Erubis::XmlHelper

  RESPONSE_STATUS = {
    200 => "200 OK",
    403 => "Forbidden",
    404 => "404 Not Found",
    500 => "500 Internal Server Error",
  }

  protected

  def get_handler
    return ErubisHandler.new()
  end

  def handle_request(env)
    handler = get_handler()
    output = handler.handle(env)
    cont_type = "text/html"
    cont_type << ";charset=#{handler.encoding}" if handler.encoding
    return [200, [["Content-Type", cont_type]], [output]]
  end

  def handle_http_error(ex)
    output = "<h2>#{h(RESPONSE_STATUS[ex.status])}</h2>\n<p>#{h(ex.message)}</p>\n"
    return [ex.status, [["Content-Type", "text/html"]], [output]]
  end

  def handle_error(ex)
    arr = ex.backtrace
    output = ""
    output <<   "<pre>\n"
    output <<   "<b>#{h(arr[0])}:<br />#{h(ex.message)} (#{h(ex.class.name)})</b>\n"
    arr[1..-1].each do |item|
      output << "        from #{h(item)}\n"
    end
    output <<   "</pre>\n"
    return [500, [["Content-Type", "text/html"]], [output]]
  end

  public

  def call(env)
    begin
      return handle_request(env)
    rescue HttpError => ex
      return handle_http_error(ex)
    rescue => ex
      return handle_error(ex)
    end
  end

  def run(env=ENV, stdout=$stdout)
    status, headers, output_arr = call(env)
    stdout << "Status: #{RESPONSE_STATUS[status]}\r\n" unless status == 200
    headers.each {|k, v| stdout << "#{k}: #{v}\r\n" }
    stdout << "\r\n"
    output_arr.each {|str| stdout << str }
  end

end


if __FILE__ == $0
  ErubisApplication.new.run()
end
