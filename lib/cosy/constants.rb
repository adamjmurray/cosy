module Cosy

#######################################
# Musical Symbols

  PITCH_CLASS = {
    'C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4, 'F'=>5,'F#'=>6, 
    'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11
  }
  $OCTAVE_OFFSET = 1  # this is a global instead of a constant so it can be altered if desired

  INTENSITY = {
    'ppp'=>15, 
    'pp' =>31,  'pianissimo'=>31,
    'p'  =>47,  'piano'=>47,
    'mp' =>63,  'mezzopiano'=>63, 'mezzo-piano'=>63,
    'mf' =>79,  'mezzoforte'=>79, 'mezzo-forte'=>79,
    'o'  =>95,  'forte'=>95,
    'ff' =>111, 'fortissimo'=>111,
    'fff'=>127    
  }

  DURATION = { # defines standard number of MIDI ticks for note durations
    'w'=>1920, 'whole'=>1920,
    'h'=>960,  'half'=>960,
    'q'=>480,  'quarter'=>480, 
    'i'=>240,  'eighth'=>240,
    's'=>120,  'sixteenth'=>120,
    'r'=>60,   'thirtysecond'=>60, 'thirty-second'=>60,
    'x'=>30,   'sixtyfourth'=>30,  'sixty-fourth'=>30
  }

#######################################
# MIDI controls

  TEMPO_LABELS = ['tempo', 'qnpm', 'qpm', 'bpm']
  PROGRAM_LABELS = ['program', 'pgm']

#######################################
# Sequence Behavior Operators
  
  OP_COUNT_LIMIT = '&'
  OP_ITER_LIMIT  = '*' # iteration (repeat) limit

  
#######################################
# Miscellaneous Contants
  
  TWO_THIRDS = 2/3.0

end