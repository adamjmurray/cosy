module Cosy  
  
  class AbstractRenderer

    def initialize
      @sequences = {}
      init
    end
    
    def init
      @prev_pitches  = AbstractRenderer.default_pitches
      @prev_octave   = AbstractRenderer.default_octave
      @prev_velocity = AbstractRenderer.default_velocity
      @prev_duration = AbstractRenderer.default_duration
    end
    
    def self.default_pitches
      [Pitch.new(0, 0, nil, '0')]
    end
    
    def self.default_octave
      60 # the middle C octave
    end
    
    def self.default_velocity
      INTENSITY['mf']
    end
    
    def self.default_duration
      DURATION['quarter']
    end
    
    def get_sequencer(cosy_syntax) 
      sequencer = Sequencer.new(cosy_syntax)
      if !sequencer.parsed?
        parser = sequencer.parser
        raise "Failed to parse: #{input}\n" + 
          "(#{parser.failure_line},#{parser.failure_column}): #{parser.failure_reason}"
      end
      return sequencer
    end
    
    def parse(cosy_syntax)
       @sequencer = get_sequencer(cosy_syntax)
    end
    
    def define_sequence(name, cosy_syntax)
      @sequences[name] = get_sequencer(cosy_syntax)
    end

    def load_sequence(name)
      if @sequences.has_key? name
        @sequencer = @sequences[name]
      else
        raise "No sequence named '#{name}' has been defined."
      end
    end

    def next_event
      event = @sequencer.next
      
      pitches  = @prev_pitches
      velocity = @prev_velocity
      duration = @prev_duration
      
      if event.is_a? Chord and event.all?{|e| e.is_a? Pitch}
        pitches = event
          
      elsif event.is_a? Chain
        event.each do |param|
          case param
          when Pitch then pitches = [param]
          when Chord then pitches = param
          when Velocity then velocity = param.value
          when Duration then duration = param.value
          else return event end
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
      
      return NoteEvent.new(pitch_values,velocity,duration)
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
