
$: << '../lib'
%w[erb erubis yaml benchmark].each {|x| require x }

ydoc = YAML.load_file('bench_context.yaml')
list = ydoc['list']
@list = list

filename = 'bench_erb.rhtml'
input = File.read(filename)
input2 = input.gsub(/\blist\b/, '@list')

erb = ERB.new(input)
erb.result(binding())

N = ($N || 10000).to_i
output = nil
Benchmark.bm(33) do |x|

  ## warm up (why need?)
  ERB.new(input).result(binding())
  Erubis::Eruby.new(input).result(binding())

  output = nil; GC.start
  x.report('ERB') do
    i = 0
    (N/10).times do
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
      output = ERB.new(input).result(binding())
    end
  end

  output = nil; GC.start
  x.report('ERB (reused)') do
    erb = ERB.new(input)
    (N/10).times do
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
      output = erb.result(binding())
    end
  end

  output = nil; GC.start
  x.report('ERB (defmethod)') do
    ERB_FILENAME = filename
    class Renderer
      extend ERB::DefMethod
      def_erb_method('render_erb', ERB_FILENAME)
      attr_accessor :list
    end
    #self.extend ERB::DefMethod
    #def_erb_method('render_erb', filename)
    r = Renderer.new
    r.list = list
    (N/10).times do
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
      output = r.render_erb()
    end
  end

  output = nil; GC.start
  x.report('Erubis::Eruby#result') do
    (N/10).times do
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
      output = Erubis::Eruby.new(input).result(binding())
    end
  end

  output = nil; GC.start
  input2 = input.gsub(/\blist\b/, '@list')
  x.report('Erubis::Eruby#evaluate') do
    (N/10).times do
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
      output = Erubis::Eruby.new(input2).evaluate(self)
    end
  end

  output = nil; GC.start
  x.report('Erubis::Eruby#result (reused)') do
    erubis = Erubis::Eruby.new(input)
    (N/10).times do
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
      output = erubis.result(binding())
    end
  end

  output = nil; GC.start
  x.report('Erubis::Eruby#evaluate (reused)') do
    erubis = Erubis::Eruby.new(input2)
    (N/10).times do
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
      output = erubis.evaluate(self)
    end
  end

  output = nil; GC.start
  x.report('Erubis::Eruby (defmethod)') do
    erubis = Erubis::Eruby.new(input)
    eval "def render_erubis(list); #{erubis.src}; end"
    (N/10).times do
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
      output = render_erubis(list)
    end
  end

  output = nil; GC.start
  x.report('Erubis::Eruby (defmethod#2)') do
    erubis = Erubis::Eruby.new(input2)
    eval "def render_erubis; #{erubis.src}; end"
    (N/10).times do
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
      output = render_erubis()
    end
  end


  File.open('hoge.output', 'w') {|f| f.write(output) }

end

__END__

$ ruby186 -s mybench2.rb -N=10000
                                       user     system      total        real
ERB                               29.940000   0.810000  30.750000 ( 31.175876)
ERB (reused)                       8.890000   0.030000   8.920000 (  8.989230)
ERB (defmethod)                    4.870000   0.010000   4.880000 (  4.913900)
Erubis::Eruby#result               9.070000   0.030000   9.100000 (  9.148731)
Erubis::Eruby#evaluate             9.130000   0.020000   9.150000 (  9.209373)
Erubis::Eruby#result (reused)      5.580000   0.020000   5.600000 (  5.666395)
Erubis::Eruby#evaluate (reused)    3.870000   0.000000   3.870000 (  3.916371)
Erubis::Eruby (defmethod)          3.780000   0.000000   3.780000 (  3.810064)
Erubis::Eruby (defmethod#2)        3.790000   0.010000   3.800000 (  3.824344)

$ ruby187 -s mybench2.rb -N=10000
                                       user     system      total        real
ERB                               16.410000   0.050000  16.460000 ( 16.549911)
ERB (reused)                       5.880000   0.010000   5.890000 (  5.930305)
ERB (defmethod)                    3.850000   0.010000   3.860000 (  3.883939)
Erubis::Eruby#result               9.320000   0.030000   9.350000 (  9.394255)
Erubis::Eruby#evaluate             9.400000   0.020000   9.420000 (  9.471952)
Erubis::Eruby#result (reused)      5.680000   0.010000   5.690000 (  5.737928)
Erubis::Eruby#evaluate (reused)    3.960000   0.010000   3.970000 (  3.992922)
Erubis::Eruby (defmethod)          3.850000   0.010000   3.860000 (  3.896049)
Erubis::Eruby (defmethod#2)        3.850000   0.010000   3.860000 (  3.872664)

$ ruby191 -s mybench2.rb -N=10000
                                       user     system      total        real
ERB                               14.370000   0.050000  14.420000 ( 14.469204)
ERB (reused)                       7.150000   0.030000   7.180000 (  7.207674)
ERB (defmethod)                    3.940000   0.010000   3.950000 (  3.983292)
Erubis::Eruby#result               9.320000   0.040000   9.360000 (  9.423159)
Erubis::Eruby#evaluate             9.550000   0.040000   9.590000 (  9.659015)
Erubis::Eruby#result (reused)      6.420000   0.020000   6.440000 (  6.479266)
Erubis::Eruby#evaluate (reused)    3.830000   0.020000   3.850000 (  3.876132)
Erubis::Eruby (defmethod)          3.690000   0.010000   3.700000 (  3.726208)
Erubis::Eruby (defmethod#2)        3.690000   0.020000   3.710000 (  3.715565)

--------------------------------------------------------------------------------

$ ruby186 -s mybench2.rb -N=10000
                                       user     system      total        real
ERB                               30.880000   0.240000  31.120000 ( 33.366328)
ERB (reused)                       9.280000   0.070000   9.350000 ( 10.036719)
ERB (defmethod)                    5.030000   0.040000   5.070000 (  5.387336)
Erubis::Eruby#result               9.460000   0.070000   9.530000 ( 10.171072)
Erubis::Eruby#evaluate             9.540000   0.070000   9.610000 ( 10.289576)
Erubis::Eruby#result (reused)      5.830000   0.050000   5.880000 (  6.286742)
Erubis::Eruby#evaluate (reused)    3.990000   0.030000   4.020000 (  4.330680)
Erubis::Eruby (defmethod)          3.890000   0.030000   3.920000 (  4.189439)
Erubis::Eruby (defmethod#2)        3.910000   0.030000   3.940000 (  4.223124)

$ ruby187 -s mybench2.rb -N=10000
                                       user     system      total        real
ERB                               16.950000   0.140000  17.090000 ( 18.276843)
ERB (reused)                       6.100000   0.050000   6.150000 (  6.578923)
ERB (defmethod)                    3.990000   0.030000   4.020000 (  4.314654)
Erubis::Eruby#result               9.690000   0.080000   9.770000 ( 10.467531)
Erubis::Eruby#evaluate             9.770000   0.080000   9.850000 ( 10.539132)
Erubis::Eruby#result (reused)      5.940000   0.040000   5.980000 (  6.434127)
Erubis::Eruby#evaluate (reused)    4.110000   0.030000   4.140000 (  4.424622)
Erubis::Eruby (defmethod)          3.990000   0.030000   4.020000 (  4.292276)
Erubis::Eruby (defmethod#2)        3.990000   0.040000   4.030000 (  4.332821)

$ ruby191 -s mybench2.rb -N=10000
                                       user     system      total        real
ERB                               14.850000   0.150000  15.000000 ( 16.020819)
ERB (reused)                       7.400000   0.070000   7.470000 (  7.971797)
ERB (defmethod)                    4.090000   0.030000   4.120000 (  4.477900)
Erubis::Eruby#result               9.720000   0.100000   9.820000 ( 10.486989)
Erubis::Eruby#evaluate             9.930000   0.100000  10.030000 ( 10.720467)
Erubis::Eruby#result (reused)      6.660000   0.060000   6.720000 (  7.201429)
Erubis::Eruby#evaluate (reused)    3.960000   0.040000   4.000000 (  4.265177)
Erubis::Eruby (defmethod)          3.810000   0.040000   3.850000 (  4.130089)
Erubis::Eruby (defmethod#2)        3.810000   0.030000   3.840000 (  4.096473)
