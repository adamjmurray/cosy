require 'cosy/renderer/abstract_osc_renderer'
require 'cosy/helper/midi_renderer_helper'

module Cosy

  class AbstractMidiRenderer < AbstractOscRenderer

    def initialize(options={})
      super
      @midi = MidiInterface.get(options[:driver])
      @channel = options.fetch(:channel, 0)
      @tempo = options.fetch(:tempo, 120)
    end   
    
    def schedule_timeline(timeline)
      timeline.each_event do |time,event|
        if event.respond_to? :channel
          channel = event.channel
        end
        channel ||= @channel 
          
        case event
        when Event::Note
          pitch,velocity,duration = event.pvdc
          schedule(time) { note_on(pitch, velocity, channel) }
          time += duration
          schedule(time) { note_off(pitch, velocity, channel) }
          
        when Event::ProgramChange
          schedule(time) { program(event.program_number, channel) }
        
        when Event::PitchBend
          schedule(time) { pitch_bend(event.midi, channel) }
          
        when Event::ControlChange
          schedule(time) { cc(event.controller_number, event.value, channel )}
            
        when Event::Tempo
          schedule(time) { tempo(event.bpm) }    
        
        when Event::OscMessage
          schedule(time) { osc(event) }
        
        else
          unhandled_event(time,event)
        end
      end
    end

    def program(program_number, channel=@channel)
      @midi.program_change(channel.to_i, program_number.to_i)
    end

    def note_on(pitch, velocity, channel=@channel)
      @midi.note_on(pitch.to_i, channel.to_i, velocity.to_i)
    end

    def note_off(pitch, velocity, channel=@channel)
      @midi.note_off(pitch.to_i, channel.to_i, velocity.to_i)
    end

    def cc(controller, value, channel=@channel)
      @midi.control_change(controller.to_i, channel.to_i, value.to_i)
    end

    def pitch_bend(value, channel=@channel)
      @midi.pitch_bend(channel.to_i, value.to_i)
    end
    
    # Override to do something useful
    def tempo(bpm)
      @tempo = bpm
    end
    
    def unhandled_event(time, event)
    end

  end

end
