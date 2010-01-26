#!/usr/bin/env ruby

# BASEDIR should be the folder that contains the mp3repo script,
# with no trailing slashes.
BASEDIR = '/Users/edu/lib/ruby/mp3repo'

$LOAD_PATH << BASEDIR

require 'rubygems'
require 'scrobbler'             
require 'text'
require 'colorize'

# custom global requires
require 'lib/status_colorizations'

APP_CONFIG = YAML.load_file(BASEDIR + '/config/global.yml')

require 'lib/globals'

require 'lib/controllers/front_controller'
require 'lib/argument_parser'
require 'lib/screen'

#require 'lib/inet_metadata'


# ==========================================================
# This code will only execute if this file is the file
# being run from the command line.
if $0 == __FILE__
  
  options = ArgumentParser::parse(ARGV)
  $verbose = options.verbose

  Screen::check_clear! unless options.command == :add
  
  fc = FrontController.new(options)
  fc.go
  
end