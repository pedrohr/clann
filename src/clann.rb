require 'uri'
require 'set'
require 'zlib'

class Clann
  attr_reader :triple_set, :clans, :properties_index

  def initialize(filename, index_output_name, clan_output_name)
    @triple_set = File.open(filename, 'r')
    @triple_set_filename = filename

    @index_output_filename = index_output_name
    @clan_output_filename = clan_output_name
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
    @clans = {}

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
          @clans[triple.first] = [triple.last]
          @properties_index.add triple.first
        else
          @clans[triple.first].push(triple.last)
        end
      end

      if line % 10000 == 0
        print "Processing line #{line}: #{(line*100)/number_triples}% complete\r"
      end
    end

    puts "\nDone."
  end

  def store_clusters
    index_marshal_dump = Marshal.dump(@properties_index)
    output_index = File.new(@index_output_filename, 'w')
    output_index.write index_marshal_dump
    output_index.close

    clans_marshal_dump = Marshal.dump(@clans)
    output_clans = File.new(@clan_output_filename, 'w')
    output_clans.write clans_marshal_dump
    output_clans.close
  end

  def load(filename)
    unless File.exists?(filename)
      return false
    end

    begin
      file = File.open(filename, 'r')
      obj = Marshal.load file.read
      file.close
      return obj
    rescue
      return false
    end
  end

  def load_indexes(filename)
    return load(filename)
  end

  def load_clann(filename)
    return load(filename)
  end

  def statistics_table
    table = []

    @clans.each_pair do |key, value|
      table.push [key, value.size]
    end

    return table.sort {|x,y| y.last <=> x.last}
  end
end
