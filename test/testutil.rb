###
### $Rev: 103 $
### $Release$
### $Copyright$
###

require 'yaml'


module TestEnhancer


  module_function


  def load_testdata(filename, options={}, &block)
    _load_yaml(filename, :doc, options, &block)
  end


  def load_yaml_document(filename, options={}, &block)
    _load_yaml(filename, :doc, options, &block)
  end


  def load_yaml_documents(filename, options={}, &block)
    _load_yaml(filename, :docs, options, &block)
  end


  def _load_yaml(filename, type, options={}, &block) # :nodoc:
    s = File.read(filename)
    if filename =~ /\.rb$/
      s =~ /^__END__$/   or raise "*** error: __END__ is not found in '#{filename}'."
      s = $'
    end
    unless options[:tabify] == false
      s = s.inject('') do |sb, line|
        sb << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }
      end
    end
    #
    case type
    when :docs
      hash_list = []
      YAML.load_documents(s) do |hash| hash_list << hash end
    when :doc
      hash_list = YAML.load(s)
    else
      raise "*** internal error"
    end
    #
    identkey = options[:identkey] || 'name'
    table = {}
    hash_list.each do |hash|
      ident = hash[identkey]
      ident          or  raise "*** #{identkey} is not found."
      table[ident]   and raise "*** #{identkey} '#{ident}' is duplicated."
      table[ident] = hash
      yield(hash) if block
    end
    #
    return hash_list
  end


  def define_testmethods(testdata_list, options={}, &block)
    identkey   = options[:identkey]   || 'name'
    testmethod = options[:testmethod] || '_test'
    testdata_list.each do |hash|
      yield(hash) if block
      ident = hash[identkey]
      s  =   "def test_#{ident}\n"
      hash.each do |key, val|
        code = "  @#{key} = #{val.inspect}\n"
        s << "  @#{key} = #{val.inspect}\n"
      end
      s  <<  "  #{testmethod}\n"
      s  <<  "end\n"
      $stderr.puts "*** load_yaml_testdata(): eval_str=<<'END'\n#{s}END" if $DEBUG
      self.module_eval s
    end
  end


end
