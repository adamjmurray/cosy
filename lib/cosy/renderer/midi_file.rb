require 'rubygems'
require 'midilib'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require File.join(cosy_root, 'cosy')

module Cosy

  class MidiRenderer
    attr_reader :midi_sequence
    
    def initialize
      @midi_sequence = MIDI::Sequence.new()
       @prev_duration = DURATION['quarter']
      @prev_velocity = INTENSITY['mf']
      
      @meta_track = addTrack
      # TODO: Cosy needs to support setting BPM inside the syntax
      @meta_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))
      @meta_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Cosy Sequence')

      @track = addTrack
      @track.events << MIDI::ProgramChange.new(0, 1, 0)
    end

    def render(input, output_file)
      @sequencer = Sequencer.new(input)
      channel = 0
      while event = @sequencer.next
        pitch, velocity, duration = getPitchVelocityDuration(event)
        
        @track.events << MIDI::NoteOnEvent.new(channel, pitch, velocity, 0)
        @track.events << MIDI::NoteOffEvent.new(channel, pitch, velocity, duration)        
      end
      File.open(output_file, 'wb'){ |file| @midi_sequence.write(file) }
    end

    ############
    private  
    
    def addTrack
      track = MIDI::Track.new(@midi_sequence)
      @midi_sequence.tracks << track
      return track
    end

    def getPitchVelocityDuration(event) 
      # TODO: refactor this into non-renderer code
      if event.is_a? Array and not event.is_a? Chord
        pitch    = event[0]
        duration = event[1]
        velocity = event[2]
      else
        pitch = event
      end

      velocity ||= @prev_velocity
      duration ||= @prev_duration
      @prev_velocity = velocity
      @prev_duration = duration
      
      if duration >= 0  
        return pitch,velocity,duration
      else
        puts 'TODO: negative durations'
      end
    end
    
    def method_missing(name, *args, &block) 
      @midi_sequence.send(name, *args, &block)
    end

  end

end

renderer = Cosy::MidiRenderer.new
renderer.render('C4:q:mf (D4:e:p)*2 E4:q:mf', 'test.mid')



