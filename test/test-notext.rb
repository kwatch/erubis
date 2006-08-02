##
## $Rev$
## $Release$
## $Copyright$
##

require File.dirname(__FILE__) + '/test'


class NoTextTest < Test::Unit::TestCase

  filename = __FILE__.sub(/\.\w+$/, '.yaml')
  testdata_list = load_yaml_datafile(filename)
  define_testmethods(testdata_list)

  def _test
    File.open(@filename, 'w') { |f| f.write(@input) }
    begin
      result = `notext #{@options} #{@filename}`
      expected = @output.gsub(/^\./, '')
      assert_text_equal(expected, result)
    ensure
      File.unlink @filename if test(?f, @filename)
    end
  end

end
