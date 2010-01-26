require 'rbrainz'
include MusicBrainz

class Artist < ActiveRecord::Base 
  has_many :albums

  def musicbrainz_lookup_releases
        
    # artist_includes = Webservice::ArtistIncludes.new(
    #   :aliases      => true,
    #   :releases     => ['Official'],
    #   :artist_rels  => true,
    #   :release_rels => true,
    #   :track_rels   => true,
    #   :label_rels   => true,
    #   :url_rels     => true
    # )
    
    query = Webservice::Query.new()
    results = query.get_artist_by_id(rbrainz_uuid, :releases => ['Official'])

    if $verbose
      puts "Found Artist:"
      print <<EOF
      ID            : #{results.id.uuid}
      Name          : #{results.name}
      Sort name     : #{results.sort_name}
      Disambiguation: #{results.disambiguation}
      Type          : #{results.type}
      Begin date    : #{results.begin_date}
      End date      : #{results.end_date}
      Aliases       : #{results.aliases.to_a.join('; ')}
      Releases      : #{results.releases.to_a.join('; ')}
EOF
    end

    albums = []
    
    results.releases.each do |album|
      query2 = Webservice::Query.new()
      album_result = query2.get_release_by_id(album.id.uuid, :artist => false, :tracks => true, :release_events => true)
      
      #pp album_result.instance_variables.to_a.join('; ') ; exit
      if $verbose
        puts
        puts "Album information for  : " 
        puts "     tags:           " + album.tags.inspect
        puts "     release_events: " + album_result.release_events[0].date.year.to_s
        puts "     artist:         " + album.artist.to_s
        print "     tracks:         "
        print album_result.tracks.to_a.join('; ') + "\n"
        # + album.tracks.inspect
        # album.tracks.each {|t| print t.inspect + ", "} #to_a.join("; ")
        puts "     id:             " + album.id.inspect
        puts "     text_script:    " + album.text_script.to_s
        puts "     types:          " + album.types.inspect
        puts "     text_language:  " + album.text_language.inspect
        puts "     title:          " + album.title.inspect
        puts "     discs:          " + album.discs.inspect
    #        puts "release_groups: " + album.release_groups.to_s
      end
      #album_date = query.release_get_date(album.id.uuid)
      #pp album_date; exit
      #pp album_result.instance_variables.to_a.join(': ')
    
      albums.push(  { :name => album.title, 
                      :rbrainz_uuid => album.id.uuid,
                      :track_count => album_result.tracks.to_a.count,
                      :type => album_result.types[0],
                      :year => album_result.release_events[0].date.year.to_s,
                     } )

      
    end

    albums

  end
  
  def self.musicbrainz_lookup_artist(artist)

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

end
