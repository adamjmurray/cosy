require 'rubygems'
require 'midilib'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require File.join(cosy_root, 'cosy')

module Cosy

  class MidiRenderer < AbstractRenderer
    attr_reader :midi_sequence
    
    def initialize
      super
      @midi_sequence = MIDI::Sequence.new()
      @meta_delta = 0
      
      @meta_track = add_track
      @meta_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Cosy Sequence')
      tempo(120)

      @track = add_track
      @channel = 1
      program(0)
    end

    def render(input, output_filename)
      parse input
      @absolute_delta = delta_time = 0
      
      while event = next_event
        case event

        when Tempo then tempo(event.value)

        when Program then program(event.value)

        when NoteEvent
          pitches, velocity, duration = event.pitches, event.velocity.to_i, event.duration.to_i
          if duration < 0
            delta_time = -duration
          else
            # TODO: special case duration 0?
            render_note(pitches, velocity, delta_time, duration)
            delta_time = 0
          end
          
        else
          raise 'Unsupported Event: #{event.inspect}'
        end
      end
      
      note_off(0, 0, 480) # pad the end a bit, otherwise seems to cut off (TODO: make this optional)  
      #print_midi
      File.open(output_filename, 'wb'){ |file| @midi_sequence.write(file) }
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
    
    def add_track
      track = MIDI::Track.new(@midi_sequence)
      @midi_sequence.tracks << track
      return track
    end
    
    # Set tempo in terms of Quarter Notes per Minute (often incorrectly referred to as BPM)
    def tempo(qnpm)
      ms_per_quarter_note = MIDI::Tempo.bpm_to_mpq(qnpm)
      @meta_track.events << MIDI::Tempo.new(ms_per_quarter_note, @meta_delta)
      @meta_delta = 0
    end
    
    def program(program_number)
      @track.events << MIDI::ProgramChange.new(@channel, program_number, 0)
    end
    
    def note_on(pitch, velocity, delta_time)
      @track.events << MIDI::NoteOnEvent.new(@channel, pitch, velocity, delta_time)
      @meta_delta += delta_time
    end
    
    def note_off(pitch, velocity, delta_time)
      @track.events << MIDI::NoteOffEvent.new(@channel, pitch, velocity, delta_time)  
      @meta_delta += delta_time
    end
    
    def render_note(pitches, velocity, delta_time, duration)
      pitches.each do |pitch|
        pitch = pitch.to_i
        note_on(pitch, velocity, delta_time)
        delta_time = 0 # if we're playing a chord the next pitch has delta_time=0
      end
      
      delta_time = duration
      pitches.each do |pitch|
        pitch = pitch.to_i
        note_off(pitch, velocity, delta_time)  
        delta_time = 0 # if we're playing a chord the next pitch has delta_time=0  
      end
    end
    
  end

end

#Cosy::MidiRenderer.new.render 'TEMPO=60; e*4; TEMPO=120; d*8; TEMPO=240; c*16', 'test.mid'
# Cosy::MidiRenderer.new.render 'TEMPO=60; c4:q c c c:1/5q*5 c4:w', 'test.mid'
#Cosy::MidiRenderer.new.render '((G4 F4 E4 D4)*4 C4):(q. i):(p mf ff)', 'test.mid'