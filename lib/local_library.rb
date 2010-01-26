
require 'active_record'
require 'lib/models/artist'
require 'lib/models/album'
require 'lib/models/song'

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
        t.column :name, :string
        t.column :status, :string
      end
      create_table(:albums) do |t|
        t.column :id, :integer
        t.column :name, :string
        t.column :status, :string
      end
      create_table(:songs) do |t|
        t.column :id, :integer
        t.column :name, :string
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
      :rbrainz_uuid => artist[:uuid]
    )
  end
  
  def change_artist(old_name, new_name)
    puts "Changing artist name from " + old_name + " to " + new_name if $verbose

    # TODO : do more robust error checking and handling here.
    FileUtils.mv(@library_dir + old_name, @library_dir + new_name)
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
      @artists[artist_name] = {
        :status => UNCHECKED,
        :model => Artist.find_by_name(artist_name),
        :albums => {}
      }
      
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
        album = Album.find_by_name(album_name)
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
          

        # song_glob = File.join(album_dir, '*')
        # song_glob.gsub!(FNAME_BAD_CHARS_REGEX, '?')
        # 
        # Dir[song_glob].each { | song |
        #   song_name = File.basename(song)
        #   next if song_name[0] == ?.
        # 
        #   # Add the song to the album's song list
        #   album.songs <<
        #     Song.new(:name => song_name.sub(/\.mp3$/, ")"))           
        # }
      }
    }   
    

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