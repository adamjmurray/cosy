cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(cosy_root, 'model/events')

module Cosy    
  
  class RendererDefaults
    
    def self.DEFAULT_PITCHES
      [Pitch.new(0, 0, nil, '0')]
    end
    
    def self.DEFAULT_OCTAVE
      60 # the middle C octave
    end
    
    def self.DEFAULT_VELOCITY
      INTENSITY['mf']
    end
    
    def self.DEFAULT_DURATION
      DURATION['quarter']
    end
  end
  
  
  class AbstractRenderer

    def initialize
      @sequences = {}
      init
    end
    
    def init
      @prev_pitches  = RendererDefaults.DEFAULT_PITCHES
      @prev_octave   = RendererDefaults.DEFAULT_OCTAVE
      @prev_velocity = RendererDefaults.DEFAULT_VELOCITY
      @prev_duration = RendererDefaults.DEFAULT_DURATION
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
          when Pitch    then pitches = [param]
          when Chord    then pitches  = param
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
      @prev_duration = duration.abs
      
      return NoteEvent.new(pitch_values,velocity,duration)
    end
    
    private
    def get_sequencer(cosy_syntax) 
      sequencer = Sequencer.new(cosy_syntax)
      if !sequencer.parsed?
        parser = sequencer.parser
        raise "Failed to parse: #{input}\n" + 
        "(#{parser.failure_line},#{parser.failure_column}): #{parser.failure_reason}"
      end
      return sequencer
    end
        
  end
end
