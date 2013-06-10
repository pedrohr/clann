require 'test/unit'
require './src/clann.rb'

# Mocks
class Clann
  def free_the_fish
    return true
  end
end

class ClannTest < Test::Unit::TestCase
  def setup
    @mapping_based = './spec/mock/mappingbased_properties_en.nt'
    @instance_types = './spec/mock/instance_types_en.nt'
    @output_clann = './clanns.gz'
    @output_index = './indexes.gz'
    
    @clann = Clann.new(@mapping_based, @output_clann, @instance_types)

    @invalid_triple_example = '<http://dbpedia.org/resource/Aristotle> <http://xmlns.com/foaf/0.1/name> ", Aristot\u00E9l\u0113s"@en .'
    @valid_triple_example = '<http://dbpedia.org/resource/Animal_Farm> <http://dbpedia.org/ontology/author> <http://dbpedia.org/resource/George_Orwell> .'
  end

  def test_should_open_triple_set_file
    file = File.open(@mapping_based, 'r')
    assert(File.identical?(@clann.triple_set, file))
  end

  def test_should_open_instance_types
    file = File.open(@instance_types, 'r')
    assert(File.identical?(@clann.instance_classes, file))
  end

  def test_should_detect_invalid_uri
    uri = '<http://dbpedia.org/resource/George_Orwell>'
    assert(Clann.isDBpediaURI?(uri))

    not_uri = 'Aristot\u00E9l\u0113s"@en'
    assert_equal(Clann.isDBpediaURI?(not_uri), false)
  end

  def test_should_process_a_valid_triple
    data = @clann.process_triple(@valid_triple_example)
    assert_equal(data, {'/Animal_Farm' => {'/George_Orwell' => '/author'}})
  end

  def test_should_ignored_invalid_triples
    data = @clann.process_triple(@invalid_triple_example)
    assert_equal(data, false)
  end

  def test_should_clusterize_predicates
    @clann.clusterize_triples
    assert_equal(@clann.clans, {
                   '/Animal_Farm' => {'/George_Orwell' => '/author'},
                   '/Aristotle' => {'/Peripatetic_school' => '/philosophicalSchool',  '/Aristotelianism' => '/philosophicalSchool', '/Physics' => '/mainInterest', '/Metaphysics' => '/mainInterest', '/Poetry' => '/mainInterest', '/Politics' => '/mainInterest', '/Reason' => '/notableIdea', '/Logic' => '/notableIdea'}
                 })
  end

  def test_should_count_triple_sets
    number = @clann.count_triple_sets
    assert_equal(number, 15)
  end

  def test_should_clear_out_inactive_memory
    assert(@clann.free_the_fish)
  end

  def test_should_store_and_load_clusters
    @clann.clusterize_triples
    @clann.store_clusters
    assert(File.exists? @output_clann)
    
    clans = @clann.load_clann(@output_clann)
    assert_equal(clans, @clann.clans)

    File.delete(@output_clann)
  end

  def test_should_filter_acceptable_classes
    assert_equal(@clann.filter_classes, {"/Autism" => "/Disease", "/Animal_Farm" => "/Book", "/Aristotle" => "/Philosopher"})
  end
end
