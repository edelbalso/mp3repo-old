class Track < ActiveRecord::Base     
  belongs_to :album                

  def self.musicbrainz_get_tracks(uuid)

    #pp uuid ; exit
    track_filter = Webservice::ReleaseIncludes.new( 
      :tracks => true,
      :counts => true
    )
    
    puts "Looking up tracks for album with uuid : " + uuid if $verbose

    query  = Webservice::Query.new()
    results = query.get_release_by_id(uuid, track_filter)
    #pp results; exit
    
    if $verbose
      puts "Found " + results.tracks.entries.size.to_s + " tracks"
      counter = 1
      results.tracks.entries.each do |r|
        #pp r ; exit
        puts
        puts "Track " + counter.to_s
        puts "-----------"
        puts "id       : " + r.id.uuid
        puts "track #  : " + counter.to_s
        puts "title    : " + r.title
        puts "duration : " + r.duration.to_s
        puts "isrcs    : " + r.isrcs.inspect
        puts "puids    : " + r.puids.inspect

        counter = counter + 1
      end
    end
    
    tracks = []
    
    counter = 1
    results.tracks.entries.each do |r|
      tracks.push({
        :name => r.title,
        :rbrainz_uuid => r.id.uuid,
        :track_number => counter,
        :duration => r.duration
      } )
      
      counter = counter + 1
    end

    tracks
  end
  
  def self.sort_track_names(files, tracks)
    
#   pp files; exit
    file_index = {}
    tn = 0
    tmp = {}
    
    files.each do |f| # for each file
#      puts f ; exit
      levdist = nil
      
     # pp tracks ; exit    
      tracks.each do |t| # check each track
        # pp f ; 
        # pp t;
        # exit
        filename = f[1][:file]
        track_filename = t[:track_number].to_s + " - " + t[:name] + ".mp3"
        newld = Text::Levenshtein.distance(filename,track_filename)
        puts newld.to_s + " :: [" + filename + "] vs [" + track_filename + "]" if $verbose
        if levdist == nil
          puts "initializing first comparative LD to " + newld.to_s  + ". Track # is "+ t[:track_number].to_s if $verbose
          levdist = newld
          tmp[:file] = f[1][:file]
          tmp[:status] = f[1][:status]
          tmp[:rbrainz_uuid] = t[:rbrainz_uuid]
          tmp[:name] = t[:name]
          tmp[:duration] = t[:duration]
          tmp[:track_number] = t[:track_number]
          tn = t[:track_number]
        elsif newld < levdist && newld >= 0 #in case error cases return negatives..
          puts "LD of " + newld.to_s + " less that old LD of " + levdist.to_s + ". Track # is "+ t[:track_number].to_s+". Changing..." if $verbose
          levdist = newld
          tmp[:file] = f[1][:file]
          tmp[:status] = f[1][:status]
          tmp[:rbrainz_uuid] = t[:rbrainz_uuid]
          tmp[:name] = t[:name]
          tmp[:duration] = t[:duration]
          tmp[:track_number] = t[:track_number]
          tn = t[:track_number]
        end
      end
      
      puts "Matched " + f[1][:file] + " with name " + tmp[:name] if $verbose
      puts "" if $verbose
      file_index[tn] = tmp.clone
      
      pp file_index if $verbose
      
    end
    
    file_index
  end
end