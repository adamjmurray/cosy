module Cosy

  PITCH_CLASS = {
    'C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4, 'F'=>5,'F#'=>6, 
    'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11
  }
  OCTAVE_OFFSET = 1  

  INTENSITY = {
    'ppp'=>15, 'pp'=>31, 'p'=>47, 'mp'=>63, 
    'mf'=>79, 'f'=>95, 'ff'=>111, 'fff'=>127    
  }

  DURATION = {
    'x'=>1, 'r'=>2, 's'=>4, 'e'=>8, 'q'=>16, 'h'=>32, 'w'=>64
  }

  # Sequence Modifier Operators
  OP_COUNT_LIMIT = '&'
  OP_ITER_LIMIT  = '*'

end