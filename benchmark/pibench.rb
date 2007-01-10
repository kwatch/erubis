
require 'yaml'
require 'benchmark'
require 'eruby'
require 'erb'
require 'erubis'
require 'erubis/tiny'
require 'erubis/engine/enhanced'


## default values
ntime = 10000
filename = 'erubybench.rhtml'
show_code = false
show_output = false
show_help = false

## parse command-line options
while ARGV[0] && ARGV[0][0] == ?-
  option = ARGV.shift
  case option
  when '-n'
    raise "-n: argument required." if ARGV.empty?
    ntime = ARGV.shift.to_i
  when '-f'
    raise "-f: argument required." if ARGV.empty?
    filename = ARGV.shift
  when '-c'
    show_code = true
  when '-o'
    show_output = true
  when '-h'
    show_help = true
  else
    raise "#{option}: unknown option."
  end
end


## show help
if show_help
  script = File.basename($0)
  puts "usage: ruby #{script} [-h] [-c] [-o] [-n N] [-f filename] > /dev/null"
  puts "  -h:       show help"
  puts "  -c:       show ruby code"
  puts "  -o:       show output"
  puts "  -n N:     repeat N times in benchmark"
  puts "  -f file:  eRuby file (*.rhtml) for benchmark"
  exit
end


## load data for benchmark
ydoc = YAML.load_file('erubybench.yaml')
data = []
ydoc['data'].each do |hash|
  #data << hash.inject({}) { |h, t| h[t[0].intern] = t[1]; h }
  h = {}; hash.each { |k, v| h[k.intern] = v } ; data << h
end
data = data.sort_by { |h| h[:code] }
#require 'pp'; pp data


## eRuby string
input1 = File.read(filename)
input2 = input1.gsub(/<%==\s*(.*?)\s*%>/m, '@{\1}@').gsub(/<%=\s*(.*?)\s*%>/m, '@!{\1}@')
input2 = input2.gsub(/<%(.*?)%>/m, '<?rb\1?>')


## procedure objects for benchmark
code = nil
convert_procs = [
  ['eruby',
     proc { code = ERuby::Compiler.new.compile_string(input1) } ],
#  ['ERB',
#     proc { code = ERB.new(input1).src } ],
  ['Erubis::Eruby',
     proc { code = Erubis::Eruby.new.convert(input1) } ],
  ['Erubis::StringBufferEruby',
     proc { code = Erubis::StringBufferEruby.new.convert(input1) } ],
  ['Erubis::StdoutEruby',
     proc { code = Erubis::StdoutEruby.new.convert(input1) } ],
  ['Erubis::PI::Eruby',
     proc { code = Erubis::PI::Eruby.new.convert(input2) } ],
  ['Erubis::TinyEruby',
     proc { code = Erubis::TinyEruby.new.convert(input1) } ],
  ['Erubis::PI::TinyEruby',
     proc { code = Erubis::PI::TinyEruby.new.convert(input2) } ],
]

evaluate_procs = [
  ['eruby',
     proc { ERuby::load(filename) } ],
#  ['ERB',
#     proc { print ERB.new(input1).result() } ],
  ['Erubis::Eruby',
     proc { print Erubis::Eruby.new.process(input1, binding()) } ],
  ['Erubis::StringBufferEruby',
     proc { print Erubis::StringBufferEruby.new.process(input1, binding()) } ],
  ['Erubis::StdoutEruby',
     proc { Erubis::StdoutEruby.new.process(input1, binding()) } ],
  ['Erubis::PI::Eruby',
     proc { print Erubis::PI::Eruby.new.process(input2, binding()) } ],
  ['Erubis::TinyEruby',
     proc { print eval(Erubis::TinyEruby.new.convert(input1)) } ],
  ['Erubis::PI::TinyEruby',
     proc { print eval(Erubis::PI::TinyEruby.new.convert(input2)) } ],
]


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

## show code or output
if show_code
  convert_procs.each do |classname, proc_obj|
    puts "---- #{classname} ----"
    puts proc_obj.call
  end
  exit
end

if show_output
  evaluate_procs.each do |classname, proc_obj|
    puts "---- #{classname} ---"
    proc_obj.call
  end
  exit
end


## do benchmark
width = 30
$stderr.puts "*** benchmark result of convertion *.rhtml into ruby code"
Benchmark.bm(width) do |x|
  GC.start()
  convert_procs.each do |classname, proc_obj|
    x.report(classname) do
      ntime.times(&proc_obj)
    end
  end
end
$stderr.puts
$stderr.puts "*** benchmark result of evaluation of *.rhtml"
Benchmark.bm(width) do |x|
  GC.start()
  evaluate_procs.each do |classname, proc_obj|
    x.report(classname) do
      ntime.times(&proc_obj)
    end
  end
end
