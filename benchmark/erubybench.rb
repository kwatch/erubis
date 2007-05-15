##
## $Rev$
## $Release$
## $Copyright$
##

require 'eruby'
require 'erb'
require 'stringio'
require 'cgi'
include ERB::Util
#module ERB::Util
#  ESCAPE_TABLE = { '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;', }
#  def h(value)
#    value.to_s.gsub(/[&<>"]/) { |s| ESCAPE_TABLE[s] }
#  end
#  module_function :h
#end

require 'erubis'
require 'erubis/engine/enhanced'
require 'erubis/engine/optimized'
require 'erubis/tiny'
require 'erubybench-lib'


## default value
defaults = {
  :ntimes    => 1000,
  :erubyfile => 'erubybench.rhtml',
  :datafile  => 'erubybench.yaml',
  :testmode  => 'execute',
  :outfile   => '/dev/null',
}


## usage
def usage(defaults)
  script = File.basename($0)
  s =  <<END
Usage: ruby #{script} [..options..] [..testnames..] > /dev/null 2> bench.log
  -h             :  help
  -n N           :  number of times to loop (default #{defaults[:ntimes]})
  -t erubyfile   :  eruby filename (default '#{defaults[:erubyfile]}')
  -f datafile    :  data filename (default '#{defaults[:datafile]}')
  -o outfile     :  output filename (default '#{defaults[:outfile]}')
  -A             :  test all targets
  -x testname,.. :  exclude testnames
  -m testmode    :  execute/convert/func (default '#{defaults[:testmode]}')
  -X             :  expand loop
  -p             :  print output
  -e             :  escape expressions
END
  return s
end


## parse command-line options
require 'optparse'
optparser = OptionParser.new
options = {}
['-h', '-n N', '-t erubyfile', '-f datafile', '-o outfile', '-A', '-e',
  '-x exclude', '-m testmode', '-X', '-p', '-D'].each do |opt|
  optparser.on(opt) { |val| options[opt[1].chr] = val }
end
begin
  targets = optparser.parse!(ARGV)
rescue => ex
  $stderr.puts "#{command}: #{ex.to_s}"
  exit(1)
end


flag_help = options['h']
ntimes    = (options['n'] || defaults[:ntimes]).to_i
$erubyfile = options['t'] || defaults[:erubyfile]
datafile  = options['f'] || defaults[:datafile]
outfile   = options['o'] || defaults[:outfile]
flag_all  = options['A']
testmode  = options['m'] || defaults[:testmode]
excludes  = options['x']
$escape   = options['e']
flag_expand = options['X'] ? true : false
flag_output = options['p'] ? true : false
$debug    = options['D']

$ntimes = ntimes

$stderr.puts "** $ntimes=#{$ntimes.inspect}, flag_expand=#{flag_expand}, options=#{options.inspect}" if $debug


## help
if flag_help
  puts usage(defaults)
  exit()
end


## load data file
require 'yaml'
ydoc = YAML.load_file(datafile)
context = ydoc
list = context['list']
if $escape
  list.each do |item|
    if item['name'] =~ / /
      item['name'] = "<#{item['name'].gsub(/ /, '&amp;')}>"
    else
      item['name'] = "\"#{item['name']}\""
    end
  end
end
#list = []
#ydoc['list'].each do |hash|
#  list << hash.inject({}) { |h, t| h[t[0].intern] = t[1]; h }
#  #h = {}; hash.each { |k, v| h[k.intern] = v } ; data << h
#end
#require 'pp'; pp list


## test definitions
testdefs = YAML.load(DATA)
testdefs.each do |testdef|
  c = testdef['class']
  testdef['code']    ||= "print #{c}.new(File.read(erubyfile)).result(binding())\n"
  testdef['compile'] ||= "#{c}.new(str).src\n"
  #require 'pp'; pp testdef
end


## select test target
if flag_all
  # nothing
elsif targets && !targets.empty?
  testdefs = targets.collect { |t| testdefs.find { |h| h['name'] == t } }.compact
  #testdefs.delete_if { |h| !targets.include?(h['name']) }
else
  testdefs.delete_if { |h| h['skip'] }
end

## exclude target
if excludes
  excludes = excluces.split(/,/)
  testdefs.delete_if { |h| excludes.include?(h['name']) }
end
#require 'pp'; pp testdefs


## generate template
def erubyfilename(name)
  case name
  when /eruby/  ;  s = '_eruby.'
  when /ERB/    ;  s = '_erb.'
  when /PI/     ;  s = '_pierubis.'
  when /Tiny/   ;  s = '_tiny.'
  when /Erubis/ ;  s = '_erubis.'
  else
    raise "#{name}: unknown name."
  end
  return $erubyfile.sub(/\./, s)
end
#
def File.write(filename, str)
  File.open(filename, 'w') { |f| f.write(str) }
end
#
if $erubyfile == defaults[:erubyfile]
  erubystr = File.read($erubyfile)
  s = erubystr
  erubystrs = {}
  if $escape
    erubystrs['eruby']  = s.gsub(/<%=(.*?)%>/, '<%= CGI.escapeHTML((\1).to_s) %>')
    erubystrs['ERB']    = s.gsub(/<%=(.*?)%>/, '<%=h \1%>')
    erubystrs['Erubis'] = s.gsub(/<%=(.*?)%>/, '<%==\1%>')
    erubystrs['Tiny']   = s.gsub(/<%=(.*?)%>/, '<%=Erubis::XmlHelper.escape_xml((\1).to_s)%>')
    erubystrs['PI']     = s.gsub(/<%=(.*?)%>/, '@{\1}@').gsub(/<%(.*?)%>/m, '<?rb\1?>')
  else
    erubystrs['eruby']  = s
    erubystrs['ERB']    = s
    erubystrs['Erubis'] = s
    erubystrs['Tiny']   = s
    erubystrs['PI']     = s.gsub(/<%=(.*?)%>/, '@!{\1}@').gsub(/<%(.*?)%>/m, '<?rb\1?>')
  end
else
  erubystr = File.read($erubyfile)
end
%w[eruby ERB PI Tiny Erubis].each do |name|
  File.write(erubyfilename(name), erubystrs[name])
end



## define test functions for each classes
str = erubystr
testdefs.each do |h|
  s = ''
  s   << "def test_execute_#{h['name']}(erubyfile, context)\n"
  s   << "  list = context['list']\n"
  if flag_expand
    $ntimes.times do
      s << "  #{h['code']}\n"
    end
  else
    s << "  $ntimes.times do\n"
    s << "    #{h['code']}\n"
    s << "  end\n"
  end
  s   << "end\n"
  #puts s
  eval s
end


## define view functions for each classes
str = erubystr
testdefs.each do |h|
  if h['compile']
    erubyfile = erubyfilename(h['name'])
    code = eval h['compile']
    s = <<-END
      def view_#{h['name']}(context)
        list = context['list']
        #{code}
      end
    END
    #puts s
    eval s
  end
end

## define tests for view functions
testdefs.each do |h|
  pr = h['return'] ? 'print ' : ''
  s = ''
  s   << "def test_func_#{h['name']}(context)\n"
  s   << "  list = context['list']\n"
  if flag_expand
    $ntimes.times do
      s << "  #{pr}view_#{h['name']}(context)\n"
    end
  else
    s << "  $ntimes.times do\n"
    s << "    #{pr}view_#{h['name']}(context)\n"
    s << "  end\n"
  end
  s   << "end\n"
  #puts s
  eval s
end


## define test for convertion
testdefs.each do |h|
  if h['compile']
    s = ''
    s   << "def test_convert_#{h['name']}(erubyfile)\n"
    s   << "  str = File.read(erubyfile)\n"
    if flag_expand
      $ntimes.times do
        s << "  src = #{h['compile']}\n"
      end
    else
      s << "  $ntimes.times do \n"
      s << "    src = #{h['compile']}\n"
      s << "  end\n"
    end
    s   << "end\n"
    #puts s
    eval s
  end
end


## define tests for caching
str = erubystr
Dir.mkdir('src') unless test(?d, 'src')
testdefs.each do |h|
  if h['compile']
    # create file to read
    erubyfile = erubyfilename(h['name'])
    code = eval h['compile']
    fname = "src/erubybench.#{h['name']}.rb"
    File.open(fname, 'w') { |f| f.write(code) }
    #at_exit do File.unlink fname if test(?f, fname) end
    # define function
    pr = h['return'] ? 'print' : ''
    s = ''
    s   << "def test_cache_#{h['name']}(erubyfile, context)\n"
    s   << "  list = context['list']\n"
    if flag_expand
      ntimes.times do
        s << "  #{pr} eval(File.read('#{fname}'))\n"
      end
    else
      s << "  $ntimes.times do\n"
      s << "    #{pr} eval(File.read('#{fname}'))\n"
      s << "  end\n"
    end
    s   << "end\n"
    #puts s
    eval s
  end
end


## output
if flag_output
  testdefs.each do |h|
    title = h['class']
    func = 'test_basic_' + h['name']
    puts "## #{h['class']}"
    __send__(func, erubyfile, data)
    puts
  end
  exit(0)
end


## rehearsal
$stdout = StringIO.new
testdefs.each do |h|
  ## execute test code
  erubyfile = erubyfilename(h['name'])
  eval h['code']
  ## execute view function
  next unless h['compile']
  v = __send__("view_#{h['name']}", context)
  print v if h['return']
  ## execute caching function
  fname = "src/erubybench.#{h['name']}.rb"
  v = eval(File.read(fname))
  print v if h['return']
end
$stdout = STDOUT


## open output file
$stdout = outfile == '-' ? STDOUT : File.open(outfile, 'w')


## change benchmark library to use $stderr instead of $stdout
require 'benchmark'
module Benchmark
  class Report
    def print(*args)
      $stderr.print(*args)
    end
  end
  module_function
  def print(*args)
    $stderr.print(*args)
  end
end


## do benchmark
width = 30
begin

  ## evaluate
  if !testmode || testmode == 'execute'
    $stderr.puts "## execute"
    Benchmark.bm(width) do |job|
      testdefs.each do |h|
        title = h['title'] || h['class']
        func = 'test_execute_' + h['name']
        GC.start
        job.report(title) do
          __send__(func, erubyfilename(h['name']), context)
        end
      end
    end
    $stderr.puts
  end

  ## convert
  if testmode == 'convert'
    $stderr.puts "## convert"
    Benchmark.bm(width) do |job|
      testdefs.each do |h|
        next unless h['compile']
        title = h['title'] || h['class']
        func = 'test_convert_' + h['name']
        GC.start
        job.report(title) do
          __send__(func, erubyfilename(h['name']))
        end
      end
    end
  end

  ## caching
  if testmode == 'cache'
    $stderr.puts "## evaluate cache file"
    Benchmark.bm(width) do |job|
      testdefs.each do |h|
        next unless h['compile']
        #title = 'cache_' + h['name']
        title = h['title'] || h['class']
        func = 'test_cache_' + h['name']
        GC.start
        job.report(title) do
          __send__(func, erubyfilename(h['name']), context)
        end
      end
    end
    $stderr.puts
  end

  ## function
  if testmode == 'func'
    $stderr.puts "## evaluate function"
    Benchmark.bm(width) do |job|
      testdefs.each do |h|
        next unless h['compile']
        #title = 'func_' + h['name']
        title = h['title'] || h['class']
        func = 'test_func_' + h['name']
        GC.start
        job.report(title) do
          __send__(func, context)
        end
      end
    end
    $stderr.puts
  end

  #Benchmark.bm(30) do |job|
  #  ## basic test
  #  testdefs.each do |h|
  #    title = h['class']
  #    func = 'test_basic_' + h['name']
  #    GC.start
  #    job.report(title) do
  #      __send__(func, erubyfile, context)
  #    end
  #  end if !testmode || testmode == 'basic'
  #
  #  ## caching function
  #  testdefs.each do |h|
  #    next unless h['compile']
  #    title = 'cache_' + h['name']
  #    func = 'test_cache_' + h['name']
  #    GC.start
  #    job.report(title) do
  #      __send__(func, erubyfile, context)
  #    end
  #  end if !testmode || testmode == 'cache'
  #
  #  ## view-function test
  #  testdefs.each do |h|
  #    next unless h['compile']
  #    title = 'func_' + h['name']
  #    func = 'test_func_' + h['name']
  #    GC.start
  #    job.report(title) do
  #      __send__(func, list)
  #    end
  #  end if !testmode || testmode == 'func'
  #
  #end

ensure
  $stdout.close() unless outfile == '-'
end

__END__

## testdefs

- name:   eruby
  class:  ERuby
  title:  eruby
  code: |
    ERuby.import(erubyfile)
  compile: |
    ERuby::Compiler.new.compile_string(str)
  return: null

- name:   ERB
  class:  ERB
  code: |
    print ERB.new(File.read(erubyfile)).result(binding())
#    eruby = ERB.new(File.read(erubyfile))
#    print eruby.result(binding())
  compile: |
    ERB.new(str).src
  return: str

- name:   ErubisEruby
  class:  Erubis::Eruby
  return: str

- name:   ErubisFastEruby
  class:  Erubis::FastEruby
  return: str

- name:   ErubisEruby2
  desc:   print _buf    #, no binding()
  class:  Erubis::Eruby2
  code: |
    #Erubis::Eruby2.new(File.read(erubyfile)).result()
    Erubis::Eruby2.new(File.read(erubyfile)).result(binding())
  return: null
  skip:   yes

- name:   ErubisEruby_cached
  class:  Erubis::Eruby
  title:  Erubis::Eruby(cached)
  code: |
    Erubis::Eruby.load_file(erubyfile).result(binding())
  compile: |
    Erubis::Eruby.load_file(erubyfile)
  return: str

- name:   ErubisExprStripped
  desc:   strip expr code
  class:  Erubis::ExprStrippedEruby
  return: str
  skip:   yes

- name:   ErubisOptimized
  class:  Erubis::OptimizedEruby
  return: str
  skip:   yes

- name:   ErubisOptimized2
  class:  Erubis::Optimized2Eruby
  return: str
  skip:   yes

- name:   ErubisArrayBuffer
  class:  Erubis::ArrayBufferEruby
#  code: |
#    Erubis::ArrayBufferEruby.new(File.read(erubyfile)).result(binding())
#  compile: |
#    Erubis::ArrayBufferEruby.new(str).src
  return: str
  skip:   no

- name:   ErubisStringBuffer
  class:  Erubis::StringBufferEruby
  return: str
  skip:   yes

- name:   ErubisStringIO
  class:  Erubis::StringIOEruby
  return: str
  skip:   yes

- name:   ErubisSimplified
  class:  Erubis::SimplifiedEruby
  return: str
  skip:   no

- name:   ErubisStdout
  class:  Erubis::StdoutEruby
  return: null
  skip:   no

- name:   ErubisStdoutSimplified
  class:  Erubis::StdoutSimplifiedEruby
  return: str
  skip:   yes

- name:   ErubisPrintOut
  class:  Erubis::PrintOutEruby
  return: str
  skip:   no

- name:   ErubisPrintOutSimplified
  class:  Erubis::PrintOutSimplifiedEruby
  return: str
  skip:   yes

- name:   ErubisTiny
  class:  Erubis::TinyEruby
  return: yes
  skip:   no

- name:   ErubisTinyStdout
  class:  Erubis::TinyStdoutEruby
  return: null
  skip:   yes

- name:   ErubisTinyPrint
  class:  Erubis::TinyPrintEruby
  return: null
  skip:   yes

- name:   ErubisPIEruby
  class:  Erubis::PI::Eruby
  code: |
    Erubis::PI::Eruby.new(File.read(erubyfile)).result(binding())
  compile: |
    Erubis::PI::Eruby.new(File.read(erubyfile)).src
  return: str

#- name:    load
#  class:   load
#  code: |
#    load($load_erubyfile)
#  compile: null
#  return: null
#  skip:    yes
