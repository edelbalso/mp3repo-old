require 'rbrainz'
include MusicBrainz


class InetMetadata

  # def initialize
  #   
  # end
  
  def self.find_albums(artist)
    
  end
  
  def self.find_artists(artist)
    find_musicbrainz_artist(artist)
  end

private                    
  def self.find_musicbrainz_artist(artist)

    artist_includes = Webservice::ArtistIncludes.new(
      :aliases      => true,
      :releases     => ['Official'],
      :artist_rels  => true,
      :release_rels => true,
      :track_rels   => false,
      :label_rels   => false,
      :url_rels     => false
    )

    artist_filter = Webservice::ArtistFilter.new( 
#      :name => artist  # for exact searches.
      :query => artist
    )

    query  = Webservice::Query.new()
    results = query.get_artists(artist_filter)
    #pp results; exit
    retval = {}

    results.each { |r| 
      #pp r; exit
      if r.score > APP_CONFIG['global']['artist_search_sensitivity']

        puts "Found an artist entry:" if $verbose

        # TODO : do this more elegantly
        r.score *= 1.00000  # Use decimals to deal with duplicate keys. GHEEETTTOOOO 
        while retval[r.score] != nil
          r.score += 0.00001
        end
        
        retval[r.score] = {}
        retval[r.score][:name] = r.entity.name
        retval[r.score][:uuid] = r.entity.id.uuid
        
        query2 = Webservice::Query.new()
        results2 = query.get_artist_by_id(r.entity.id.uuid, artist_includes)
        if $verbose
          print <<EOF
          ID            : #{results2.id.uuid}
          Name          : #{results2.name}
          Sort name     : #{results2.sort_name}
          Disambiguation: #{results2.disambiguation}
          Type          : #{results2.type}
          Begin date    : #{results2.begin_date}
          End date      : #{results2.end_date}
          Aliases       : #{results2.aliases.to_a.join('; ')}
          Releases      : #{results2.releases.to_a.join('; ')}
EOF
        end
        #pp results2; exit
        retval[r.score][:release_count] = results2.releases.to_a.count
      end
    }
    #pp retval; exit
    retval

  end
  
  def self.find_musicbrainz_albums(artist)
    
  end
end