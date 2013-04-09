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
    @output_clann = './clanns.gz'
    @output_index = './indexes.gz'
    
    @clann = Clann.new(@mapping_based, @output_index, @output_clann)

    @invalid_triple_example = '<http://dbpedia.org/resource/Aristotle> <http://xmlns.com/foaf/0.1/name> ", Aristot\u00E9l\u0113s"@en .'
    @valid_triple_example = '<http://dbpedia.org/resource/Animal_Farm> <http://dbpedia.org/ontology/author> <http://dbpedia.org/resource/George_Orwell> .'
  end

  def test_should_open_triple_set_file
    file = File.open(@mapping_based, 'r')
    assert(File.identical?(@clann.triple_set, file))
  end

  def test_should_detect_invalid_uri
    uri = '<http://dbpedia.org/resource/George_Orwell>'
    assert(Clann.isDBpediaURI?(uri))

    not_uri = 'Aristot\u00E9l\u0113s"@en'
    assert_equal(Clann.isDBpediaURI?(not_uri), false)
  end

  def test_should_process_a_valid_triple
    data = @clann.process_triple(@valid_triple_example)
    assert_equal(data, ['<http://dbpedia.org/ontology/author>', ['<http://dbpedia.org/resource/Animal_Farm>','<http://dbpedia.org/resource/George_Orwell>']])
  end

  def test_should_ignored_invalid_triples
    data = @clann.process_triple(@invalid_triple_example)
    assert_equal(data, false)
  end

  def test_should_clusterize_predicates
    @clann.clusterize_triples
    assert_equal(@clann.clans, {'<http://dbpedia.org/ontology/author>' => [['<http://dbpedia.org/resource/Animal_Farm>', '<http://dbpedia.org/resource/George_Orwell>']],
                   '<http://dbpedia.org/ontology/philosophicalSchool>' => [['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Peripatetic_school>'], ['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Aristotelianism>']],
                   '<http://dbpedia.org/ontology/mainInterest>' => [['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Physics>'], ['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Metaphysics>'], ['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Poetry>'], ['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Politics>']],
                   '<http://dbpedia.org/ontology/notableIdea>' => [['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Reason>'], ['<http://dbpedia.org/resource/Aristotle>', '<http://dbpedia.org/resource/Logic>']]
                 })
    assert_equal(@clann.properties_index, Set.new(['<http://dbpedia.org/ontology/author>', '<http://dbpedia.org/ontology/philosophicalSchool>', '<http://dbpedia.org/ontology/mainInterest>', '<http://dbpedia.org/ontology/notableIdea>']))
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
    assert(File.exists? @output_index)

    index = @clann.load_indexes(@output_index)
    assert_equal(index, @clann.properties_index)
    
    clans = @clann.load_clann(@output_clann)
    assert_equal(clans, @clann.clans)

    File.delete(@output_clann, @output_index)
  end
end
