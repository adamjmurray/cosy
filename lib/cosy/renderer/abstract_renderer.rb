module Cosy  
  
  class AbstractRenderer

    def initialize
      init
    end
    
    def init
      @prev_pitches  = default_pitches
      @prev_octave   = default_octave
      @prev_velocity = default_velocity
      @prev_duration = default_duration
    end
    
    def default_pitches
      [Pitch.new(0, 0, nil, '0')]
    end
    
    def default_octave
      60 # the middle C octave
    end
    
    def default_velocity
      INTENSITY['mf']
    end
    
    def default_duration
      DURATION_NAME['quarter']
    end
    
    def parse(input)
      @sequencer = Sequencer.new(input)
      if !@sequencer.parsed?
        parser = @sequencer.parser
        raise "Failed to parse: #{input}\n" + 
          "(#{parser.failure_line},#{parser.failure_column}): #{parser.failure_reason}"
      end
    end

    def next_event
      event = @sequencer.next
      
      pitches  = @prev_pitches
      velocity = @prev_velocity
      duration = @prev_duration
      
      if event.is_a? Chord 
        pitches = event
          
      elsif event.is_a? Chain
        event.each do |param|
          if param.is_a? Pitch
            pitches = [param]
          elsif param.is_a? Chord
            pitches = param
          elsif param.is_a? Velocity
            velocity = param.value
          elsif param.is_a? Duration
            duration = param.value
          else
            raise "Unimplemented chain value: #{param.class}"
          end
        end
   
      elsif event.is_a? Pitch
        pitches = [event]
        
      elsif event.is_a? Velocity
        velocity = event.value
        
      elsif event.is_a? Duration
        duration = event.value  

      else
        return event 
      end
      
      pitch_values = []
      pitches.each do |pitch|
        pitch.octave = @prev_octave if not pitch.has_octave?
        @prev_octave = pitch.octave
        pitch_values << pitch.value
      end

      @prev_pitches = pitches
      @prev_velocity = velocity
      @prev_duration = duration
      
      return NoteEvent.new(pitches,velocity,duration)
    end
    
  end
  
  class NoteEvent
    attr_accessor :pitches, :velocity, :duration
    def initialize(pitches, velocity, duration)
      if pitches.is_a? Array
        @pitches = pitches
      else 
        @pitches = [pitches] 
      end
      @velocity, @duration = velocity, duration
    end
    
    def eql?(other)
      self == other
    end
    
    def ==(other)
      other.is_a? NoteEvent and other.pitches==@pitches and 
        other.velocity==@velocity and other.duration==@duration
    end
    
    def to_s
      inspect
    end
    
    def inspect
      s = "Note<"
      s += @pitches.inspect
      s += ',' + @velocity.inspect if @velocity
      s += ',' + @duration.inspect if @duration
      s += ">"
      return s
    end
  end
  
end
