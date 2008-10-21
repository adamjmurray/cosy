module Cosy

  PITCH_CLASS = {
    'C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4, 'F'=>5,'F#'=>6, 
    'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11
  }
  $OCTAVE_OFFSET = 1  # this is a global instead of a constant so it can be altered if desired

  INTENSITY = {
    # If I go much below 24, ppp is barely audible with GM piano sound
    # But maybe that's a dumb reason to not make it
    # ppp=>15 pp=>31, p=>47
    # This should be easily configurable with a command node
    'ppp'=>24, 'pp'=>36, 'p'=>48, 'mp'=>63, 'mf'=>79, 
    'forte'=>95, 'o'=>95,
    'ff'=>111, 'fff'=>127    
  }

  DURATION = { # standard number of MIDI ticks for these note durations:
    'w'=>1920, 'h'=>960, 'q'=>480, 'i'=>240, 's'=>120, 'r'=>60, 'x'=>30
  }
  
  DURATION_NAME = {
    'whole'=>1920, 'half'=>960, 'quarter'=>480, 'eighth'=>240, 
    'sixteenth'=>120, 'thirtysecond'=>60, 'sixtyfourth'=>30 
  }

  # Sequence Behavior Operators
  OP_COUNT_LIMIT = '&'
  OP_ITER_LIMIT  = '*'
  
  TWO_THIRDS = 2/3.0

end