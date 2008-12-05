module Cosy

#######################################
# Musical Symbols

  PITCH_CLASS = {
    'C'  => 0, 
    'C#' => 1, 
    'D'  => 2, 
    'D#' => 3, 
    'E'  => 4,
    'F'  => 5,
    'F#' => 6, 
    'G'  => 7, 
    'G#' => 8, 
    'A'  => 9,
    'A#' => 10,
    'B'  => 11
  }

  ACCIDENTAL = {
    '#' =>  1, 
    'b' => -1, 
    '+' =>  0.5,
    '_' => -0.5
  }

  INTENSITY = {
    'ppp'=>15,
    'pp' =>31,  'pianissimo'=>31,
    'p'  =>47,  'piano'=>47,
    'mp' =>63,  'mezzopiano'=>63, 'mezzo-piano'=>63,
    'mf' =>79,  'mezzoforte'=>79, 'mezzo-forte'=>79,
    'fo' =>95,  'forte'=>95,
    'ff' =>111, 'fortissimo'=>111,
    'fff'=>127    
  }

  # Define standard number of MIDI ticks for note durations.
  DURATION = { 
    'w'=>1920, 'whole'=>1920,
    'h'=>960,  'half'=>960,
    'q'=>480,  'quarter'=>480, 
    'ei'=>240, 'eighth'=>240,
    's'=>120,  'sixteenth'=>120,
    'r'=>60,   'thirtysecond'=>60, 'thirty-second'=>60,
    'x'=>30,   'sixtyfourth'=>30,  'sixty-fourth'=>30
  }
  
  DURATION_MODIFIER = {
    '.' => 1.5,
    't' => 2/3.0
  }
  
  INTERVAL_QUALITY = {
    # This is case insensitive except when there is only one letter (m != M)
    # So call downcase() when looking up in this map, unless the string length is 1
    'M'=>:major,    'maj'=>:major,      'major'=>:major,
    'm'=>:minor,    'min'=>:minor,      'minor'=>:minor,
    'p'=>:perfect,  'per'=>:perfect,    'perfect'=>:perfect,
    'P'=>:perfect,  'aug'=>:augmented,  'augmented'=>:augmented,
                    'dim'=>:diminished, 'diminished'=>:diminished
  }
  
  # Maps unison, second, third, fourth, etc to number of semitones
  # in the perfect/major interval.
  INTERVAL_DEGREE = {
    0 => 11, # under mod 7 arithmetic, the 0 degree is a 7th (unison is a special case)
    1 => 0,
    2 => 2,
    3 => 4,
    4 => 5,
    5 => 7,
    6 => 9,
    7 => 11
  }
  
  # Maps semitones to interval quality and degree
  INTERVAL_VALUES = {
    0  => [:perfect, 0],
    1  => [:minor, 2],
    2  => [:major, 2],
    3  => [:minor, 3],
    4  => [:major, 3],
    5  => [:perfect, 4],
    6  => [:diminished, 5],
    7  => [:perfect, 5],
    8  => [:minor, 6],
    9  => [:major, 6],
    10 => [:minor, 7],
    11 => [:major, 7]
  }

#######################################
# MIDI controls

  TEMPO_LABELS = ['tempo', 'qnpm', 'qpm', 'bpm']
  PROGRAM_LABELS = ['program', 'pgm']
  CHANNEL_LABELS = ['channel', 'chan']
  CC_LABELS = ['control', 'cc']
  PITCH_BEND_LABELS = ['pitch-bend', 'pitchbend', 'bend', 'pb']
  
#######################################
# Sequence Behavior Operators
  
  OP_COUNT_LIMIT = '&'
  OP_ITER_LIMIT  = '*' # iteration (repeat) limit

#######################################
# Open Sound Control

  OSC_PORT_LABEL = 'osc_port'
  OSC_HOST_LABEL = 'osc_host'
  
#######################################
# Interpreter behaviors

  $OCTAVE_OFFSET = 1  # this is a global instead of a constant so it can be altered at runtime if desired
  
#######################################
# Rendering options

  DEFAULT_OCTAVE = 4
  DEFAULT_PITCH_CLASS = PITCH_CLASS['C']
  DEFAULT_VELOCITY = INTENSITY['mf']
  DEFAULT_DURATION = DURATION['quarter']
  
  OCTAVE_MODE_LABEL = 'octave_mode'
  OCTAVE_MODE_VALUES = {
    'previous' => :previous, 'prev' => :previous, 'p' => :previous,
    'nearest'  => :nearest,  'near' => :nearest,  'n' => :nearest
  }
  DEFAULT_OCTAVE_MODE = :previous
  
end