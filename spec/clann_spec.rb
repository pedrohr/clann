require 'test/unit'
require './src/clann.rb'

class ClannTest < Test::Unit::TestCase
  def setup
    @mapping_based = "./spec/mock/mappingbased_properties_en.nt"
    @clann = Clann.new(@mapping_based)
  end

  def test_should_read_input_file
    file = File.open(@mapping_based, 'r')
    
    assert(File.identical?(@clann.triple_set, file))
  end

  
end
