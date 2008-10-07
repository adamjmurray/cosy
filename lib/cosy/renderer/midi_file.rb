require 'rubygems'
require 'midilib'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require File.join(cosy_root, 'cosy')

module Cosy

  class MidiRenderer < AbstractRenderer
    attr_reader :midi_sequence
    
    def initialize
      init
      @midi_sequence = MIDI::Sequence.new()
      @delta_time = 0
      
      @meta_track = addTrack
      # TODO: Cosy needs to support setting BPM inside the syntax
      @meta_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))
      @meta_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Cosy Sequence')

      @track = addTrack
      @track.events << MIDI::ProgramChange.new(0, 1, 0)
    end

    def render(input, output_file)
      @sequencer = Sequencer.new(input)
      if !@sequencer.parsed?
        parser = @sequencer.parser
        raise "Failed to parse: #{input}\n" + 
          "(#{parser.failure_line},#{parser.failure_column}): #{parser.failure_reason}"
      end
      channel = 0
      while event = @sequencer.next
        pitches, velocity, duration = getPitchesVelocityDuration(event)    
        if duration < 0
          @delta_time = -duration
        else
          # TODO: special case duration 0?
          pitches.each do |pitch|
            @track.events << MIDI::NoteOnEvent.new(channel, pitch, velocity, @delta_time)
            @delta_time = 0
          end
          pitches.each do |pitch|
            @track.events << MIDI::NoteOffEvent.new(channel, pitch, velocity, duration)  
            duration = 0      
          end
        end
      end
      @track.events << MIDI::NoteOffEvent.new(1, 0, 0, 480) # pad the end a bit, otherwise seems to cut off (TODO: make this optional)  
      #print_midi
      File.open(output_file, 'wb'){ |file| @midi_sequence.write(file) }
    end
    
    def print_midi
      @midi_sequence.each do |track|
        puts "*** track name \"#{track.name}\""
        puts "instrument name \"#{track.instrument}\""
        puts "#{track.events.length} events"
        track.each do |event|
          event.print_decimal_numbers = true # default = false (print hex)
          event.print_note_names = true # default = false (print note numbers)
          puts event
        end
      end
    end

    ############
    private  
    
    def addTrack
      track = MIDI::Track.new(@midi_sequence)
      @midi_sequence.tracks << track
      return track
    end
    
    def method_missing(name, *args, &block) 
      @midi_sequence.send(name, *args, &block)
    end
  end

end


# Cosy::MidiRenderer.new.render 'c4 dfff4', 'test.mid'
