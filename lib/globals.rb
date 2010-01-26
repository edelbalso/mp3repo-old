# A regular expression for making file names palatable
# to the Dir class file name globbing.
FNAME_BAD_CHARS_REGEX = /['"\s]/

# Status labels and colors.
UNCHECKED = 'U'
NEW_TO_BE_PROCESSED = 'N'
STAGED = 'S'
COMMITTED = 'C'
REMOTE_ONLY = 'R'

STATUS_COLORS = {}
STATUS_COLORS[UNCHECKED] = :white
STATUS_COLORS[NEW_TO_BE_PROCESSED] = :red
STATUS_COLORS[STAGED] = :yellow
STATUS_COLORS[COMMITTED] = :green
STATUS_COLORS[REMOTE_ONLY] = :cyan

# data subdir name
DATADIRNAME = '.mp3repo'