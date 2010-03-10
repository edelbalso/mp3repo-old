
require 'active_record'
require 'lib/models/artist'
require 'lib/models/album'
require 'lib/models/track'

require 'ftools'

class LocalLibrary

  attr_reader :artists
  
  def initialize
    
    @artists = Hash.new
    @library_dir = ''
    print "Scanning local dir..." if $verbose
    
    locate

    if @library_dir == ''
      puts "No mp3repo database initialized in this folder. Switch to a valid mp3repo library or use --init to init."
      exit
    end
    
    scan_dir
    puts "done!" if $verbose
  end

  def db_connect
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database => Dir.pwd + File::SEPARATOR + DATADIRNAME + File::SEPARATOR + 'data' + File::SEPARATOR + 'sqlite.db'
    )
    
  end
  
  def self.db_connect
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database => Dir.pwd + File::SEPARATOR + DATADIRNAME + File::SEPARATOR + 'data' + File::SEPARATOR + 'sqlite.db'
    )
    
  end
  
  def self.init_db!
    
    # check if .mp3repo exists.
    if File.directory? Dir.pwd + File::SEPARATOR + DATADIRNAME
      puts "The directory ./" + DATADIRNAME + " exists. Erasing..."
      FileUtils.rm_rf Dir.pwd + File::SEPARATOR + DATADIRNAME
    end
    
    puts "Creating " + DATADIRNAME + " folders."
    Dir.mkdir(Dir.pwd + File::SEPARATOR + DATADIRNAME)
    Dir.mkdir(Dir.pwd + File::SEPARATOR + DATADIRNAME + File::SEPARATOR + 'data')
                   
    puts "Creating database connection..."
    db_connect
    puts "Creating tables..."
    ActiveRecord::Schema.define do
      create_table(:artists) do |t|
        t.column :id, :integer
        t.column :rbrainz_uuid, :string
        t.column :fs_key, :string
        t.column :name, :string
        t.column :status, :string
      end
      create_table(:albums) do |t|
        t.column :id, :integer
        t.column :artist_id, :integer
        t.column :rbrainz_uuid, :string
        t.column :fs_key, :string
        t.column :name, :string
        t.column :release_type, :string
        t.column :year, :string
        t.column :track_count, :integer
        t.column :status, :string
      end
      create_table(:tracks) do |t|
        t.column :id, :integer
        t.column :album_id, :integer
        t.column :rbrainz_uuid, :string
        t.column :fs_key, :string
        t.column :name, :string
        t.column :track_number, :integer
        t.column :duration, :integer
        t.column :status, :string
      end
    end
      
  end

  def self.get_albums(artist)
  end
  
  def add_artist(artist)

    @artists[artist] = {}
    @artists[artist][:model] = Artist.create(
      :name => artist[:name],
      :status => STAGED,
      :rbrainz_uuid => artist[:uuid],
      :fs_key => artist[:name]
    )
  end
  
  def add_album(artist, album)
   #pp artist ; exit
    parsed_type = album[:type][album[:type].rindex('#')+1..album[:type].size]

    @artists[artist][:albums][album[:name]] = {}
    @artists[artist][:albums][album[:name]][:model] = Album.create(
      :name => album[:name],
      :artist_id => @artists[artist][:model][:id],
      :status => "S",
      :release_type => parsed_type,
      :year => album[:year],
      :track_count => album[:track_count],
      :rbrainz_uuid => album[:rbrainz_uuid],
      :fs_key => artist + "::" + album[:name]
      
    )

  end
  
  def add_track(artist,album,track)
    # pp track ; exit
    if $verbose 
      puts "Adding track " + track[:name] + " to library..."
    end

    Track.create(
      :name => track[:name],
      :status => STAGED,
      :rbrainz_uuid => track[:rbrainz_uuid],
      :duration => track[:duration],
      :fs_key => artist + "::" + album + "::" + track[:file],
      :track_number => track[:track_number]
      
    )
  end
  
  def change_artist(old_name, new_name)
    if old_name.strip == new_name.strip
      puts "Skipping... old and new are the same!" if $verbose
    else
      puts "Changing artist name from " + old_name + " to " + new_name if $verbose

      # TODO : do more robust error checking and handling here.
      FileUtils.mv(@library_dir + old_name, @library_dir + new_name)
    end
  end
  
  def change_album(artist, old_name, new_name)
    if old_name.strip == new_name.strip
      puts "Skipping... old and new are the same!" if $verbose
    else

      puts "Changing album name from " + old_name + " to " + new_name + " for artist " + artist if $verbose

      # TODO : do more robust error checking and handling here.
      FileUtils.mv(@library_dir + artist + '/' + old_name, @library_dir + artist + '/' + new_name)
    end
  end
  
  def change_track(artist, album, old_name, new_name, output = true)
    if old_name.strip == new_name.strip
      puts "Skipping... old and new are the same!" if $verbose
    else
      if $verbose
        puts "Changing track name from " + old_name + " to " + new_name + " for artist " + artist + " and album " + album 
      elsif output
        puts old_name + " -> " + new_name
      end

      # TODO : do more robust error checking and handling here.
      FileUtils.mv(@library_dir + artist + '/' + album + '/' + old_name, @library_dir + artist + '/' + album + '/' + new_name)
    end
  end
  
  
private

=begin rdoc
  Looks for a .mp3repo folder in the current directory. If one exists,
  it updates the @library_dir, otherwise leaves it blank. Also finds the
  current directory.
=end
  def locate()
    
    search = Dir.pwd()

    search = search.split(File::SEPARATOR)

    while not File.directory? File.join(search) + File::SEPARATOR + DATADIRNAME and File.join(search) != ''
      search.pop
    end
    
    if File.directory? File.join(search) + File::SEPARATOR + DATADIRNAME
      @library_dir = File.join(search) + File::SEPARATOR
    end 

    
  end

  
  def scan_dir
    db_connect
    
    # scan local directory for all albums and songs : 
    artist_glob = File.join(@library_dir, '*')
    artist_glob.gsub!(FNAME_BAD_CHARS_REGEX, '?')

    Dir[artist_glob].each { | artist_dir |
      next if artist_dir[0] == ?. # Skip dot files
      next if File.basename(artist_dir) == 'sqlite.db'

      # p File.basename(artist_dir)
      # exit  

      artist_name = File.basename(artist_dir)
#      pp artist_name;exit
      @artists[artist_name] = {
        :status => UNCHECKED,
        :model => Artist.find_by_fs_key(artist_name),
        :albums => {}
      }
      
      #pp @artists[artist_name] ; exit
      if @artists[artist_name][:model] == nil
        @artists[artist_name][:status] = NEW_TO_BE_PROCESSED
      else
        @artists[artist_name][:status] = @artists[artist_name][:model].status
      end
      
   
      album_glob = File.join(artist_dir, '*')
      album_glob.gsub!(FNAME_BAD_CHARS_REGEX, '?')

      Dir[album_glob].each { | album_dir |
        next if album_dir[0] == ?.

        album_name = File.basename(album_dir)
        album = Album.find_by_fs_key(artist_name + "::" + album_name)
        @artists[artist_name][:albums][album_name] = {
          :model => album,
          :status => UNCHECKED
        }
        
        #pp @artists
        
        if @artists[artist_name][:albums][album_name][:model] == nil
          @artists[artist_name][:albums][album_name][:status] = NEW_TO_BE_PROCESSED
        else
          @artists[artist_name][:albums][album_name][:status] = album.status
        end
          

        song_glob = File.join(album_dir, '*')
        song_glob#.gsub!(FNAME_BAD_CHARS_REGEX, '?')
         
        @artists[artist_name][:albums][album_name][:tracks] = {}
#        @artists[artist_name][:albums][album_name][:tracks] = {}

        tracknum = 1
        Dir[song_glob].each { | song |
          
           ext = File.extname(song)
           
           song_name = File.basename(song)
           next if song_name[0] == ?. 
          
          if ext.upcase == ".MP3"  #.sub(/\.mp3$/, ")")         
            # Add the song to the album's song list
            track = Track.find_by_fs_key(artist_name + "::" + album_name + "::" + song_name);
            @artists[artist_name][:albums][album_name][:tracks][tracknum] = {}
            @artists[artist_name][:albums][album_name][:tracks][tracknum][:file] = song_name
            @artists[artist_name][:albums][album_name][:tracks][tracknum][:model] = track
            @artists[artist_name][:albums][album_name][:tracks][tracknum][:status] = UNCHECKED
            
            if @artists[artist_name][:albums][album_name][:tracks][tracknum][:model] == nil
              @artists[artist_name][:albums][album_name][:tracks][tracknum][:status] = NEW_TO_BE_PROCESSED
            else
              @artists[artist_name][:albums][album_name][:tracks][tracknum][:status] = track.status
            end
            
            tracknum += 1
          end
           
        }
      }
    }
    
    #pp @artists ; exit

    # Look each entry up in DB :
    # @artists.each do | artist_name, artist |
    #   if Artist.find_by_name(artist_name)
    #     artist.status = STAGED
    #   else
    #     artist.status = NEW_TO_BE_PROCESSED
    #   end
    #   
    #   artist.albums.each do | album |
    #     if artist.status == NEW_TO_BE_PROCESSED
    #       album.status = NEW_TO_BE_PROCESSED
    #     end
    #   end
    # end
    
    @artists
    
  end
end