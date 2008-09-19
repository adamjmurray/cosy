module Cosy

  PITCH_CLASS = {
    'C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4, 'F'=>5,'F#'=>6, 
    'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11
  }
  $OCTAVE_OFFSET = 1  # this is a global instead of a constant so it can be altered if desired

  INTENSITY = {
    'ppp'=>15, 'pp'=>31, 'p'=>47, 'mp'=>63, 
    'mf'=>79, 'f'=>95, 'ff'=>111, 'fff'=>127    
  }

  DURATION = { # standard number of MIDI ticks for these note durations:
    'x'=>30, 'r'=>60, 's'=>120, 'e'=>240, 'q'=>480, 'h'=>960, 'w'=>1920,
    'sixtyfourth'=>30, 'thirtysecond'=>60, 'sixteenth'=>120, 
    'eighth'=>240, 'quarter'=>480, 'half'=>960, 'whole'=>1920
  }

  # Sequence Behavior Operators
  OP_COUNT_LIMIT = '&'
  OP_ITER_LIMIT  = '*'
  
  TWO_THIRDS = 2/3.0

end