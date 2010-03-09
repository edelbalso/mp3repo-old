require 'lib/local_library'
require 'lib/models/artist'

class FrontController

  attr_reader :options
#  attr_accessor :options

  def initialize(options)

    @options = options
    # trim trailing slashes
    @options.artist = @options.artist.chomp('/') if @options.artist
    @options.album = @options.album.chomp('/') if @options.album

  end
  
  def go
    
    if options.command == :init_db
      LocalLibrary::init_db!
      exit        
    end    

    if options.command == :list
      list
    elsif options.command == :add
      add
    end
  end

private

  def list
    # scan and load local library
    local = LocalLibrary.new

    if options.album
      if options.artist
        p local.artists[options.artist].albums[options.album]
      end

    elsif options.artist
      puts "looking up albums for [" + options.artist + "]" if $verbose
      
      unless local.artists[options.artist][:model]
        puts                     
        puts "Please add artist to library to allow internet lookups."
        puts "ie: Model not instantiated for this artist." if $verbose
        exit
      end
      releases = Album.musicbrainz_lookup_releases(local.artists[options.artist][:model])

      organized_releases = {}
      
      releases.each do |r|
        parsed_type = r[:type][r[:type].rindex('#')+1..r[:type].size] + 's'
        unless organized_releases[parsed_type]
           organized_releases[parsed_type] = [r]
        else
           organized_releases[parsed_type].push r
        end
      end
      
      #pp organized_releases
      longest = 0
      releases.each {|r| if longest < r[:name].size.to_i ; longest = r[:name].size.to_i ; end }
      if longest > 35
        longest = 35
      end
      puts "Internet Album List".colorize(:yellow)
      puts "-------------------"
      organized_releases.each do |type, orls|
        puts
        puts "  ,..." + type + "...,"
        #pp local.artists[options.artist][:albums]
        orls.each do |orl|
          prefix = "    "
          if local.artists[options.artist][:albums].has_key?(orl[:name])  
            if local.artists[options.artist][:albums][orl[:name]][:status] != "N"
              prefix = local.artists[options.artist][:albums][orl[:name]][:status].stat_color + " | "
            end
          end
            
          if orl[:name].size.to_i > 50
            puts prefix + orl[:year] + " - " + orl[:name] + " " +  "(" + orl[:track_count].to_s + " tracks)"
          else
            puts prefix + orl[:year] + " - " + orl[:name] + " " * (longest + 1 - orl[:name].size.to_i).abs +  "(" + orl[:track_count].to_s + " tracks)"
          end
        end
      end

      #pp local.artists[options.artist]
      puts
      puts "Not in Library".colorize(:yellow)
      puts "--------------"

       local.artists[options.artist][:albums].sort.each { | name, album_data | 
         puts album_data[:status].stat_color + " | " + name if album_data[:status] == "N"
       }

      
      puts


    else  #default action
      #pp local.artists; exit;
      
      other = ""
      
      local.artists.sort.each { | name , artist_data |
        if artist_data[:status] == "N"
          other = other + artist_data[:status].stat_color + " | " + name + "\n"
        else
          puts artist_data[:status].stat_color + " | " + name
        end
      }
      
      puts
      puts "New to library ".colorize(:yellow)
      puts "---------------"
      puts other
    end
  end
  
  def add
    local = LocalLibrary.new
    #pp options; exit
    if options.album
      if options.artist
        if local.artists[options.artist][:status] == 'N'
          puts "ERROR: Artist not in library. Please add artist with -a first."
        else
          results = Album.musicbrainz_lookup_releases(local.artists[options.artist][:model])
          match = ""
          match_distance = -1
          results.each do |r|
            ld = Text::Levenshtein.distance(options.album,r[:name])
            if match_distance < 0
              match = r
              match_distance = ld
            elsif ld < match_distance
              match = r
              match_distance = ld
            end
            
            #puts "local name: " + options.album + ", Result: " + r[:name] + ", [" + Text::Levenshtein.distance(options.album,r[:name]).to_s + "]"
          end
          
          print "Likely album name is '" + match[:name] + "'. Use it? [y] "
          reply = $stdin.gets
          
          if reply.strip.upcase == 'Y' || reply.strip == "" || reply.strip.upcase == "YES" || reply.strip.upcase == "YUP"
            if options.album != match[:name]
              local.change_album(options.artist,options.album, match[:name])
              options.album == match[:name]
            end
            local.add_album(options.artist,match)
              
          else

            puts 
            puts "Albums Found".colorize(:yellow)
            puts "------------"
            results.each do |r|
              parsed_type = r[:type][r[:type].rindex('#')+1..r[:type].size]
              #pp r; exit
              puts r[:rbrainz_uuid] + " | " + r[:year].to_s + " - " + r[:name] + " (" + r[:track_count].to_s + " tracks, " + parsed_type + ")"
            end
            puts
            puts "Please Choose an Album from Above".colorize(:yellow)
            puts "---------------------------------"
            print "Enter uuid: "
            reply = $stdin.gets
            
            results.each do |r|

              if r[:rbrainz_uuid] == reply.strip
                print "Use album : " + r[:name] + "? [y] "
                confirmation = $stdin.gets
                if confirmation.strip.upcase == 'Y' || confirmation.strip == "" || confirmation.strip.upcase == "YES" || confirmation.strip.upcase == "YUP"
                  puts "DONE"
                  local.change_album(options.artist,options.album, r[:name])
                  options.album = r[:name]
                  local.add_album(options.artist,r)
                end
              end
            end
          end
          
        end
      end

    elsif options.artist

      puts "Adding artist: " + options.artist if $verbose

      if local.artists[options.artist][:status] != NEW_TO_BE_PROCESSED
        puts "ERROR: This artist has already been added."
        exit
      end

      puts "Looking up " + options.artist + " on internet..." if $verbose
      artists = Artist::musicbrainz_lookup_artist(options.artist)
      # pp artists; exit

      if artists.size > 0
        puts "Internet artist lookup returned " + artists.size.to_s + " result(s)" if $verbose
        likely_artist = artists.sort { |a,b| b[0] <=> a[0] } [0][1] # sort array for highest match score.
      else
        puts "ERROR: That artist name could not be found on the internet. Try renaming folder."
        exit
      end

      puts "Local Artist Name    : " + options.artist if $verbose

      #pp other_artists.sort { |a,b| b[0] <=> a[0] }; exit


      if $verbose
        print "Likely Artist Name   : " + likely_artist[:name]
        puts " (" + artists.sort { |a,b| b[0] <=> a[0]}[0][0].to_s + "% match, " + likely_artist[:release_count].to_s + " releases)"
      end

      artists.delete( artists.sort { |a,b| b[0] <=> a[0] } [0][0] )

      names = "" 
      print "Other possible names : " if $verbose
      if artists.size > 0
        artists.sort { |a,b| b[0] <=> a[0] }.each { |rank, a|
          names += a[:name]
          if $verbose
            names += " (" + rank.to_s + "% match, "+ a[:release_count].to_s+" releases), "
          else
            names += ", "
          end
        }
        puts names.chop.chop if $verbose
        puts if $verbose
      else
        puts "NONE" if $verbose
      end
      
      
      if artists.size > 0
        puts "Likely artist match:"
        puts likely_artist[:uuid] + " | " + likely_artist[:name] + ", " + likely_artist[:release_count].to_s + " releases"
        puts
        puts "Others:"
        artists.each do |rank, a|
          puts a[:uuid] + " | " + a[:name] + ", " + a[:release_count].to_s + " releases"
        end
        
        puts
        print "Use likely artist? [y] "
        reply = $stdin.gets
        
        if reply.strip.upcase == 'Y' || reply.strip == "" || reply.strip.upcase == "YES" || reply.strip.upcase == "YUP"
          local.add_artist(likely_artist)
        else
          # TODO : Figure out how to tie artist to rbrainz if name is changed.
          print "Please enter artist uuid : "
          reply = $stdin.gets

          artist_choice = ""
          artists.each do | rank, a |
            if a[:uuid] == reply.strip
              artist_choice = a
            end
          end

          puts "You chose " + artist_choice[:name]
          if options.artist != artist_choice[:name]
            local.change_artist(options.artist,artist_choice[:name])
            options.artist = artist_choice[:name]
          end
          local.add_artist(artist_choice)
        end
        
        
      elsif likely_artist[:name] == options.artist
        
        print "Artist name contains no errors, adding artist to database..." if $verbose
#        p likely_artist; exit
        local.add_artist(likely_artist)
        
        puts options.artist + " successfully added to library." unless $verbose
        puts "done!" if $verbose

      elsif likely_artist[:name] != options.artist
        print "Use suggested name; " + likely_artist[:name] +" (" + likely_artist[:release_count].to_s + " releases)? [y] "
        reply = $stdin.gets

        if reply.strip.upcase == 'Y' || reply.strip == "" || reply.strip.upcase == "YES" || reply.strip.upcase == "YUP"
          local.change_artist(options.artist,likely_artist[:name])
          options.artist = likely_artist[:name]
          local.add_artist(options.artist)
        else
          # TODO : Figure out how to tie artist to rbrainz if name is changed.
          puts "Please type new name : "
          reply = gets
          puts "Changing name to " + reply
        end
      end


    else
      puts "ERROR: No album or artist specified."
    end

  end
end