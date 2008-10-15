module Cosy  
  
  class AbstractRenderer

    def init
      @prev_pitches  = [0]
      @prev_duration = DURATION_NAME['quarter']
      @prev_velocity = INTENSITY['mf']
    end
    
    ############
    private  
    
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
        pitches = event.collect{|p| if p.respond_to? :value then p.value else p end}
          
      elsif event.is_a? Chain
        event.each do |param|
          if param.is_a? Pitch
            pitches = [param.value]
          elsif param.is_a? Chord
            pitches = param.collect{|p| if p.respond_to? :value then p.value else p end}
          elsif param.is_a? Velocity
            velocity = param.value
          elsif param.is_a? Duration
            duration = param.value
          else
            raise "Unimplemented chain value: #{param.class}"
          end
        end
   
      elsif event.is_a? Pitch
        pitches = [event.value]
        
      elsif event.is_a? Velocity
        velocity = event.value
        
      elsif event.is_a? Duration
        duration = event.value  

      else
        return event 
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
      @pitches, @velocity, @duration = pitches, velocity, duration
    end
  end
  
end
