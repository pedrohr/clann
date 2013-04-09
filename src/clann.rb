require 'uri'
require 'set'

class Clann
  attr_reader :triple_set

  def initialize(filename)
    @triple_set = File.open(filename, 'r')
    @triple_set_filename = filename
  end

  def self.isDBpediaURI?(uri)
    unless uri[0] == '<' and uri[uri.size-1] == '>'
      return false
    end

    uri = uri[1..uri.size-2]

    begin
      parse = URI(uri)
      unless parse.scheme == "http" and parse.host == "dbpedia.org"
        return false
      end
    rescue URI::InvalidURIError => e
      return false
    end

    return true
  end

  def process_triple(triple)
    spo = triple.split(" ")
    s = spo[0].strip
    p = spo[1].strip
    o = spo[2].strip

    unless Clann.isDBpediaURI?(o)
      return false
    else
      return [p, [s,o]]
    end
  end

  def count_triple_sets
    line = 0

    output = `wc -l #{@triple_set_filename}`

    return output.split(" ").first.to_i-1
  end

  def free_the_fish
    return `purge`
  end

  def clusterize_triples
    clans = {}

    print "Clearing out inactive RAM memory...\r"
    free_the_fish

    print "Counting triples on #{@triple_set_filename}\r"
    number_triples = count_triple_sets
    puts "Clustering #{number_triples} triples of #{@triple_set_filename}"

    # Ignoring first comment line of DBpedia files
    line = 0
    triple_set.readline

    @properties_index = Set.new    

    triple_set.each_line do |t|
      triple = process_triple(t)
      line += 1

      if triple
        unless @properties_index.include? triple.first
          clans[triple.first] = [triple.last]
          @properties_index.add triple.first
        else
          clans[triple.first].push(triple.last)
        end
      end

      if line % 10000 == 0
        print "Processing line #{line}: #{(line*100)/number_triples}% complete\r"
      end
    end

    return clans
  end
end
