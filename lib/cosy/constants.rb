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
  $OCTAVE_OFFSET = 1  # this is a global instead of a constant so it can be altered if desired

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
    'fo' =>95,  'forte'=>95,      'o'=>95,
    'ff' =>111, 'fortissimo'=>111,
    'fff'=>127    
  }

  # Define standard number of MIDI ticks for note durations.
  DURATION = { 
    'w'=>1920, 'whole'=>1920,
    'h'=>960,  'half'=>960,
    'q'=>480,  'quarter'=>480, 
    'ei'=>240, 'eighth'=>240,      'i'=>240, 
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
    'M'=>:major,                        'maj'=>:major,      'major'=>:major,
    'm'=>:minor,                        'min'=>:minor,      'minor'=>:minor,
    'p'=>:perfect,    'P'=>:perfect,    'per'=>:perfect,    'perfect'=>:perfect,
                                        'aug'=>:augmented,  'augmented'=>:augmented,
                                        'dim'=>:diminished, 'diminished'=>:diminished
  }
  
  # Maps unison, second, third, fourth, etc to number of semitones
  # in the perfect/major interval.
  INTERVAL_DEGREE = {
    0 => 11, # under mod 7 arithmetic, the 0 degree is a 7th
    1 => 0,
    2 => 2,
    3 => 4,
    4 => 5,
    5 => 7,
    6 => 9,
    7 => 11
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
# Miscellaneous Contants
  
  TWO_THIRDS = 2/3.0

end