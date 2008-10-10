module Cosy
  class AbstractRenderer

    def init
      @prev_pitches  = [0]
      @prev_duration = DURATION_NAME['quarter']
      @prev_velocity = INTENSITY['mf']
    end
    
    ############
    private  

    def getPitchesVelocityDuration(event) 
      pitches  = @prev_pitches
      velocity = @prev_velocity
      duration = @prev_duration
      
      if event.is_a? Chord 
        pitches = event.collect{|the| if the.respond_to? :value then the.value else the end}
          
      elsif event.is_a? Chain
        event.each do |evt|
          if evt.is_a? Pitch
            pitches = [evt.value]
          elsif evt.is_a? Chord
            pitches = evt.collect{|e| if e.respond_to? :value then e.value else e end}
          elsif evt.is_a? Velocity
            velocity = evt.value
          elsif evt.is_a? Duration
            duration = evt.value
          else
            raise "Unimplemented chain value: #{evt.class}"
          end
        end
   
      elsif event.is_a? Pitch
        pitches = [event.value]
        
      elsif event.is_a? Velocity
        velocity = event.value
        
      elsif event.is_a? Duration
        duration = event.value  
        
      elsif event.is_a? Fixnum
        pitches = [event]

      else
        raise "Unexpected event type #{event.class} (#{event.inspect})"
      end

      @prev_pitches = pitches
      @prev_velocity = velocity
      @prev_duration = duration
      
      return pitches,velocity,duration
    end
    
  end
end
