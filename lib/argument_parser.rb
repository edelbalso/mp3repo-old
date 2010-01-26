require 'optparse'  
require 'ostruct'


class ArgumentParser
  
  def self.parse(args)
    options = OpenStruct.new
    options.command = :list
    options.artist = false
    options.album = false

    OptionParser.new do |opts|
      opts.banner = "Usage: mp3repo.rb [commands] artist[/album]" 
      opts.separator ""
      opts.separator "Commands: [Default command is 'list' if none specified]"

      opts.on("-l","--list", "Lists all artists in library [default]") do
        options.command = :list
        options
      end

      opts.on("-a","--add", "Adds an artist or album to the local database") do
        options.command = :add
        options
      end

      opts.on("--init","Initializes a local repository in the current directory") do
        options.command = :init_db
        options
      end

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end
    
      opts.on_tail("-h","--help","Show this message") do
        puts opts

        puts
        puts "Statuses :"    

        puts "    " + UNCHECKED.colorize(STATUS_COLORS[UNCHECKED]) + ' : Unchecked       - You should never see this. Please contact me if you do.'
        puts "    " + NEW_TO_BE_PROCESSED.colorize(STATUS_COLORS[NEW_TO_BE_PROCESSED]) + 
                                                                     ' : Non-verified    - New artist/album in local directory that hasn\'t passed veririfcation and been staged.'
        puts "    " + STAGED.colorize(STATUS_COLORS[STAGED]) +       ' : Staged          - Artist/album passed verification and is in local DB.'
        puts "    " + COMMITTED.colorize(STATUS_COLORS[COMMITTED]) + ' : Committed       - Artist/album is backed up'
        puts "    " + REMOTE_ONLY.colorize(STATUS_COLORS[REMOTE_ONLY]) + 
                                                                     ' : Remote Only     - Artist/album is backed up but deleted from your local library.'
        puts
        exit
      end
      
      begin
        opts.parse!(args)
      rescue OptionParser::InvalidOption
        puts "ERROR: " + $!
        if options.verbose
          raise
        end
        exit
      end
      
      options
    end

    if args.size > 0
      options.artist = args[0].split('/')[0] if ARGV
      options.album = args[0].split('/')[1]
    end
    
    # error check arguments :
    if options.artist
      unless File.directory? Dir.pwd() + '/' + options.artist
        puts "ERROR: Artist '" + options.artist + "' not found."
        exit
      end
    end
    if options.album
      if ! options.artist
        puts "ERROR: Please specify artist."
        exit
      elsif ! File.directory? Dir.pwd() + '/' + options.artist + '/' + options.album
        puts "ERROR: Album '" + options.album + "' not found for artist '" + options.artist + "'."
        exit
      end
    end
    
    options
    
  end
end