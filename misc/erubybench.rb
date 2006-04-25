##
## $Rev$
## $Release$
## $Copyright$
##

require 'eruby'
require 'erb'
require 'erubis'


## usage
def usage
  s =  "Usage: ruby #{$0} [-h] [-n N] [-f file] [-d file] 2>/dev/null\n"
  s << "  -h      :  help\n"
  s << "  -n N    :  number of repeat\n"
  s << "  -f file :  eruby filename (default 'ex.eruby')\n"
  s << "  -d file :  data filename (default 'data.yaml')\n"
  return s
end


## parse command-line options
filename = 'ex.eruby'
datafile = 'data.yaml'
n = 1000
flag_help = false
while !ARGV.empty? && ARGV[0][0] == ?-
  opt = ARGV.shift
  case opt
  when '-n'  ;  n = ARGV.shift.to_i
  when '-f'  ;  filename = ARGV.shift
  when '-d'  ;  datafile = ARGV.shift
  when '-h', '--help'  ;  flag_help = true
  else       ;  raise "#{opt}: invalid option."
  end
end
puts "** n=#{n.inspect}, filename=#{filename.inspect}, datafile=#{datafile.inspect}"


## help
if flag_help
  puts usage()
  exit()
end


## load data file
require 'yaml'
ydoc = YAML.load_file(datafile)
data = []
ydoc.each do |hash|
  data << hash.inject({}) { |h, t| h[t[0].intern] = t[1]; h }
  #h = {}; hash.each { |k, v| h[k.intern] = v } ; data << h
end


## open /dev/null
$devnull = File.open("/dev/null", 'w')


## define test method for each class
codes = {
  'ERuby'  => 'ERuby.import(filename)',
  'ERB'    => 'print ERB.new(File.read(filename)).result(binding())',
  'Erubis' => 'print Erubis::Eruby.new(File.read(filename)).result(binding())',
}
codes.each do |target, code|
  s = ''
  s << "def test_#{target}(filename, data)\n"
  s << "  $stdout = $devnull\n"
  n.times do
    s << '  ' << code << "\n"
  end
  s << "  $stdout = STDOUT\n"
  s << "end\n"
  #puts s
  eval s
end


## rehearsal
$stdout = $devnull
codes.each { |target, code| eval code }
#ERuby.import(filename)
#print ERB.new(File.read(filename)).result(binding())
#print Erubis::Eruby.new(File.read(filename)).result(binding())
$stdout = STDOUT


## do benchmark
require 'benchmark'
begin
  Benchmark.bmbm(8) do |job|
    job.report("Eruby:") do
      test_ERuby(filename, data)
    end
    job.report("ERB:") do
      test_ERB(filename, data)
    end
    job.report("Erubis:") do
      test_Erubis(filename, data)
    end
  end
ensure
  $devnull.close()
end


__END__

## define helper method
require 'benchmark'
class Benchmark::Job
  def myreport(title, n, &block)
    report(title) do
      begin
        $stdout = $devnull
        n.times do
          n.times do
            block.call
          end
        end
      rescue => ex
        p ex
        raise ex
      ensure
        $stdout = STDOUT
      end
    end
  end
end


## do benchmark
begin
  Benchmark.bmbm(8) do |job|
    job.myreport("Eruby:", n) do
      ERuby.import(filename)
    end
    job.myreport("ERB:", n) do
      eruby = ERB.new(File.read(filename))
      print eruby.result(binding())
    end
    job.myreport("Erubis:", n) do
      eruby = Erubis::Eruby.new(File.read(filename))
      print eruby.result(binding())
    end
  end
ensure
  $devnull.close()
end


__END__

Benchmark.bmbm(8) do |job|
  job.report("ERuby:") do
    $stdout = $devnull
    n.times do
      n.times do
        ERuby.import(filename)
      end
    end
    $stdout = STDOUT
  end
  job.report("ERB:") do
    $stdout = $devnull
    n.times do
      n.times do
        eruby = ERB.new(File.read(filename))
        print eruby.result(binding())
      end
    end
    $stdout = STDOUT
  end
  job.report("Erubis:") do
    $stdout = $devnull
    n.times do
      n.times do
        eruby = Erubis::Eruby.new(File.read(filename))
        print eruby.result(binding())
      end
    end
    $stdout = STDOUT
  end
end
