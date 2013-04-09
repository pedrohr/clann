class Clann
  attr_reader :triple_set

  def initialize(filename)
    @triple_set = File.open(filename, 'r')
  end

  
end
