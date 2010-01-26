require 'rubygems'
require 'activerecord'
require 'fileutils'
require 'colorize'  
require 'rbrainz'
include MusicBrainz

# Create a Jukebox class. A Jukebox holds a hash (dictionary)
# whose keys are artist names and values are artist objects.
class Jukebox        

  # Declare an instance variable. Declaring it isn't
  # necessary, but by using "attr_accessor" two accessor
  # methods (a getter and a setter) are created for us.
  attr_accessor :local_artists

  # This method is called by the constructor when a new
  # jukebox is created.
  def initialize
    @local_artists = Hash.new

    unless File.directory? Dir.pwd + File::SEPARATOR + DATADIRNAME
      puts "ERROR : No mp3repo database initialized. Please try again with -i."
      exit
    end
    
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :dbfile => Dir.pwd + '/.mp3repo/data/sqlite.db'
    )
  end
  
  # Return a list of all of the artists' albums.
  def local_albums(artist)
    return @local_artists[artist].albums.collect { | a | a.name }
  end
  
  def show_artists!        
    @local_artists.sort_by { |artist_name, artist| artist_name.capitalize}.each {|artist_name, artist | 
      puts artist.status.colorize(STATUS_COLORS[artist.status]) + ' | ' + artist.name
    }    
  end                           
     
  def process_album(artist,album)
     
  end  
                   
  def find_albums_on_internet(artist) 
    results = self.__find_last_fm_albums(artist)
  end
        
  def __find_last_fm_albums(artist)
    a = Scrobbler::Artist.new(artist)
    results = {}
    a.top_albums.each{ |album|
      alb = Scrobbler::Album.new(artist, album.name, :include_info => true)
      album.release_date = alb.release_date
    }
    
  end

  
  def __find_musicbrainz_artist(artist)

    artist_includes = Webservice::ArtistIncludes.new(
      :aliases      => true,
      :releases     => ['Album', 'Official'],
      :artist_rels  => true,
      :release_rels => true,
      :track_rels   => true,
      :label_rels   => true,
      :url_rels     => true
    )
       
    artist_filter = Webservice::ArtistFilter.new( 
#      :name => artist  # for exact searches.
      :query => artist
    )
                  
    query  = Webservice::Query.new()
    results = query.get_artists(artist_filter)
    results.each { |r| puts r.score.to_s + "  | " + r.entity.name if r.score > 50 }
    exit
    
    
    a = Webnew(artist)
    results = {}
    a.top_albums.each{ |album|
      alb = Scrobbler::Album.new(artist, album.name, :include_info => true)
      album.release_date = alb.release_date
    }
    
  end
  
   
  
  def load_dir
    
  end
  

end                        
     

class Artist < ActiveRecord::Base 
  has_many :albums  
  attr_accessor :status
  
  def after_initialize
    @status = UNCHECKED
  end
end

class Album < ActiveRecord::Base     
  has_many :songs
  belongs_to :artist  
  
  attr_accessor :status
  
  def after_initialize
    @status = UNCHECKED
  end

end

class Song < ActiveRecord::Base     
  belongs_to :album                
end
