module Cosy    

  class AbstractRenderer
    
    def initialize(options={})
      @options = options
      input = options[:input]
      if input.is_a? Sequencer
        @sequencer = input
      elsif input
        parse(input)
      end
      @sequences = {}
      init()
    end
    
    def init
      @prev_pitches  = [Pitch.new(DEFAULT_PITCH_CLASS, DEFAULT_OCTAVE)]
      @prev_octave   = DEFAULT_OCTAVE
      @prev_velocity = DEFAULT_VELOCITY
      @prev_duration = DEFAULT_DURATION 
    end
    
    def parse(cosy_syntax)
       @sequencer = Sequencer.new(cosy_syntax)
    end
    
    def define_sequence(name, cosy_syntax)
      @sequences[name] = Sequencer.new(cosy_syntax)
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

      if event.is_a? Interval
        pitches = @prev_pitches.map{|pitch| pitch+event}

      elsif event.is_a? Chord and event.all?{|e| e.is_a? Pitch}
        pitches = event

      elsif event.is_a? Chain
        event.each do |param|
          case param
          when Pitch    then pitches = [param]
          when Chord    then pitches  = param
          when Velocity then velocity = param.value
          when Duration then duration = param.value
          else             
            return event 
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
      @prev_duration = duration.abs

      return NoteEvent.new(pitch_values,velocity,duration)
    end
        
  end
  
end
