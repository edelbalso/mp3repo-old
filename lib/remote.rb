require 'rubygems'
require 'progressbar'
require 'net/ftp'

class Remote

  attr_accessor :connection_type
  
  def initialize()
    @connection_type = :ftp
    @ftp = nil
  end
  
  def connect()
    if @connection_type == :ftp
      begin
        print "connecting to FTP... "
        @ftp = Net::FTP.new(APP_CONFIG['datastore']['FTP']['host'])
        puts "#{@ftp.last_response}"
        print "logging in...        "
        @ftp.login( APP_CONFIG['datastore']['FTP']['username'], APP_CONFIG['datastore']['FTP']['password'])
        puts "#{@ftp.last_response}"
        @ftp.binary = true
        @ftp.passive = false
      rescue
        raise "Could not establish FTP connection"
      end
    end
  end
  
  def put(file,dest)
    if @connection_type == :ftp
      # puts "Chaging directory to : " + APP_CONFIG['datastore']['FTP']['path']
      # @ftp.chdir(APP_CONFIG['datastore']['FTP']['path'])
      # puts "ftp reponse: #{@ftp.last_response}"
      filesize = Float(File.size(file))
      r_size = 0
      pbar = ProgressBar.new('upload',filesize)
      puts "source      : " + file
      puts 'destination : ' + APP_CONFIG['datastore']['FTP']['path'] + dest
      @ftp.putbinaryfile(file, APP_CONFIG['datastore']['FTP']['path'] + dest) { |data|
#        r_size += data.size
        pbar.inc(data.size)
#        percent = (r_size/filesize)*100
#        printf("Transfered : %i r", percent)
#        $stdout.flush
      }
      pbar.finish
      puts "#{@ftp.last_response}"
#      print @ftp.list('all')
      #@ftp.putbinaryfile( file, dest )
    end
  end
  
  def close()
    if @connection_type == :ftp
      print "closing ftp connection. "
      @ftp.close
    end
  end
end