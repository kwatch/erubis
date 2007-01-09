##
## $Rev$
## $Release$
## $Copyright$
##

require 'eruby'
require 'erb'
require 'stringio'

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
}


## usage
def usage(defaults)
  script = File.basename($0)
  s =  <<END
Usage: ruby #{script} [..options..] > /dev/null 2> bench.log
  -h             :  help
  -n N           :  number of times to loop (default #{defaults[:ntimes]})
  -F erubyfile   :  eruby filename (default '#{defaults[:filename]}')
  -f datafile    :  data filename (default '#{defaults[:datafile]}')
  -t testname,.. :  target testnames
  -x testname,.. :  exclude testnames
  -T testtype    :  basic/cache/func
  -X             :  expand loop
  -S             :  use /dev/null instead of stdout
END
  return s
end


## parse command-line options
require 'optparse'
optparser = OptionParser.new
options = {}
['-h', '-n N', '-F erubyfile', '-f datafile', '-t targets', '-x exclude',
 '-T testtype', '-X', '-S', '-D'].each do |opt|
  optparser.on(opt) { |val| options[opt[1].chr] = val }
end
begin
  filenames = optparser.parse!(ARGV)
rescue => ex
  $stderr.puts "#{command}: #{ex.to_s}"
  exit(1)
end


flag_help = options['h']
ntimes    = (options['n'] || defaults[:ntimes]).to_i
erubyfile = options['F'] || defaults[:erubyfile]
datafile  = options['f'] || defaults[:datafile]
targets   = options['t']
testtype  = options['T']
excludes  = options['x']
$expand   = options['X'] ? true : false
use_devnull = options['S'] ? true : false
$debug    = options['D']

$ntimes = ntimes

$stderr.puts "** $ntimes=#{$ntimes.inspect}, $expand=#{$expand}, use_devnull=#{use_devnull}, options=#{options.inspect}" if $debug


## help
if flag_help
  puts usage(defaults)
  exit()
end


## load data file
require 'yaml'
ydoc = YAML.load_file(datafile)
data = []
ydoc['data'].each do |hash|
  data << hash.inject({}) { |h, t| h[t[0].intern] = t[1]; h }
  #h = {}; hash.each { |k, v| h[k.intern] = v } ; data << h
end
data = data.sort_by { |h| h[:code] }
#require 'pp'; pp data


## test definitions
testdefs_str = <<END
- name:   ERuby
  class:  ERuby
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

- name:   ErubisEruby2
  desc:   print _buf    #, no binding()
  class:  Erubis::Eruby2
  code: |
    #Erubis::Eruby2.new(File.read(erubyfile)).result()
    Erubis::Eruby2.new(File.read(erubyfile)).result(binding())
  return: null
  skip:   yes

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

#- name:   ErubisArrayBuffer
#  class:  Erubis::ArrayBufferEruby
#  code: |
#    Erubis::ArrayBufferEruby.new(File.read(erubyfile)).result(binding())
#  compile: |
#    Erubis::ArrayBufferEruby.new(str).src
#  return: str
#  skip:   no

- name:   ErubisStringBuffer
  class:  Erubis::StringBufferEruby
  return: str
  skip:   no

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
  skip:   no

- name:   ErubisPrintOut
  class:  Erubis::PrintOutEruby
  return: str
  skip:   no

- name:   ErubisPrintOutSimplified
  class:  Erubis::PrintOutSimplifiedEruby
  return: str
  skip:   no

- name:   ErubisTiny
  class:  Erubis::TinyEruby
  return: yes
  skip:   no

- name:   ErubisTinyStdout
  class:  Erubis::TinyStdoutEruby
  return: null
  skip:   no

- name:   ErubisTinyPrint
  class:  Erubis::TinyPrintEruby
  return: null
  skip:   no

#- name:    load
#  class:   load
#  code: |
#    load($load_erubyfile)
#  compile: null
#  return: null
#  skip:    yes

END
testdefs = YAML.load(testdefs_str)

## manipulate
testdefs.each do |testdef|
  c = testdef['class']
  testdef['code']    ||= "print #{c}.new(File.read(erubyfile)).result(binding())\n"
  testdef['compile'] ||= "#{c}.new(str).src\n"
  #require 'pp'; pp testdef
end


## select test target
if targets.nil?
  testdefs.delete_if { |h| h['skip'] }
elsif targets.downcase != 'all'
  targets = targets.split(/,/)
  testdefs.delete_if { |h| !targets.include?(h['name']) }
end

## exclude target
if excludes
  excludes = excluces.split(/,/)
  testdefs.delete_if { |h| excludes.include?(h['name']) }
end

#require 'pp'; pp testdefs


str = File.read(erubyfile)
testdefs.each do |h|
  ## define test functions for each classes
  s = ''
  s << "def test_basic_#{h['name']}(erubyfile, data)\n"
  s << "  $stdout = $outstream\n"
  if $expand
    $ntimes.times do
      s << '  ' << h['code']  #<< "\n"
    end
  else
    s << "  $ntimes.times do\n"
    s << "    #{h['code']}\n"
    s << "  end\n"
  end
  s << "  $stdout = STDOUT\n"
  s << "end\n"
  #puts s
  eval s
end


## define view functions for each classes
str = File.read(erubyfile)
testdefs.each do |h|
  if h['compile']
    code = eval h['compile']
    s = <<-END
      def view_#{h['name']}(data)
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
  s << "def test_func_#{h['name']}(data)\n"
  s << "  $stdout = $outstream\n"
  if $expand
    $ntimes.times do
      s << "  #{pr}view_#{h['name']}(data)\n"
    end
  else
    s << "  $ntimes.times do\n"
    s << "    #{pr}view_#{h['name']}(data)\n"
    s << "  end\n"
  end
  s << "  $stdout = STDOUT\n"
  s << "end\n"
  #puts s
  eval s
end


## define tests for caching
str = File.read(erubyfile)
Dir.mkdir('src') unless test(?d, 'src')
testdefs.each do |h|
  if h['compile']
    # create file to read
    code = eval h['compile']
    fname = "src/erubybench.#{h['name']}.rb"
    File.open(fname, 'w') { |f| f.write(code) }
    #at_exit do File.unlink fname if test(?f, fname) end
    # define function
    pr = h['return'] ? 'print' : ''
    s = ''
    s << "def test_cache_#{h['name']}(erubyfile, data)\n"
    s << "  $stdout = $outstream\n"
    if $expand
      ntimes.times do
        s << "  #{pr} eval(File.read('#{fname}'))\n"
      end
    else
      s << "  $ntimes.times do\n"
      s << "    #{pr} eval(File.read('#{fname}'))\n"
      s << "  end\n"
    end
    s << "  $stdout = STDOUT\n"
    s << "end\n"
    #puts s
    eval s
  end
end


## open /dev/null
$outstream = use_devnull ? File.open("/dev/null", 'w') : STDOUT


## rehearsal
$stdout = $outstream
testdefs.each do |h|
  ## execute test code
  eval h['code']
  ## execute view function
  next unless h['compile']
  v = __send__("view_#{h['name']}", data)
  print v if h['return']
  ## execute caching function
  fname = "src/erubybench.#{h['name']}.rb"
  v = eval(File.read(fname))
  print v if h['return']
end
$stdout = STDOUT


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
begin
  Benchmark.bm(30) do |job|
    ## basic test
    testdefs.each do |h|
      title = h['class']
      func = 'test_basic_' + h['name']
      GC.start
      job.report(title) do
        __send__(func, erubyfile, data)
      end
    end if !testtype || testtype == 'basic'

    ## caching function
    testdefs.each do |h|
      next unless h['compile']
      title = 'cache_' + h['name']
      func = 'test_cache_' + h['name']
      GC.start
      job.report(title) do
        __send__(func, erubyfile, data)
      end
    end if !testtype || testtype == 'cache'

    ## view-function test
    testdefs.each do |h|
      next unless h['compile']
      title = 'func_' + h['name']
      func = 'test_func_' + h['name']
      GC.start
      job.report(title) do
        __send__(func, data)
      end
    end if !testtype || testtype == 'func'

  end
ensure
  $outstream.close() if use_devnull
end
