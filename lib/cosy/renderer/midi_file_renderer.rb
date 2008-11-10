require 'rubygems'
require 'midilib'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require File.join(cosy_root, 'cosy')

module MIDI
  class Track
    def insert(event, time) 
      event.time_from_start = time
      events << event
      return event
    end
  end
  
  class Sequence
    def create_track(name=nil)
      track = MIDI::Track.new(self)
      track.name = name if name
      tracks << track
      return track  
    end
  end
end

module Cosy

  class MidiRenderer < AbstractRenderer
    attr_reader :midi_sequence
    
    def initialize
      super
      @midi_sequence = MIDI::Sequence.new()
      @channel = 1
      @time = 0
      
      @meta_track = @midi_sequence.create_track 'Cosy Sequence'
      @track = @midi_sequence.create_track 'Track 1'
      
      tempo(120)
      program(0)
    end

    def render(input, output_filename)
      parse input
      
      while event = next_event
        case event

        when Tempo then tempo(event.value)

        when Program then program(event.value)

        when NoteEvent
          pitches, velocity, duration = event.pitches, event.velocity, event.duration
          if duration >= 0
            notes(pitches, velocity, duration)
          else            
            rest(-duration)
          end
          
        else raise 'Unsupported Event: #{event.inspect}' end
      end
      
      # pad the end a bit, otherwise seems to cut off (TODO: make this optional)  
      @time += 480
      note_off(0, 0) 
      
      @meta_track.recalc_delta_from_times
      @track.recalc_delta_from_times
      
      print_midi
      File.open(output_filename, 'wb') { |file| @midi_sequence.write(file) }
    end
    
    def print_midi
      @midi_sequence.each do |track|
        puts "\n*** track name \"#{track.name}\""
        #puts "instrument name \"#{track.instrument}\""
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
    
    # Set tempo in terms of Quarter Notes per Minute (aka BPM)
    def tempo(qnpm)
       ms_per_quarter_note = MIDI::Tempo.bpm_to_mpq(qnpm)
       event = MIDI::Tempo.new(ms_per_quarter_note)
       @meta_track.insert(event, @time)
     end

     def program(program_number)
       event = MIDI::ProgramChange.new(@channel, program_number)
       @track.insert(event, @time)
     end
    
    def note_on(pitch, velocity)
      event = MIDI::NoteOnEvent.new(@channel, pitch.to_i, velocity.to_i)
      @track.insert(event, @time)
    end
    
    def note_off(pitch, velocity)
      event = MIDI::NoteOffEvent.new(@channel, pitch.to_i, velocity.to_i)
      @track.insert(event, @time)
    end
    
    def notes(pitches, velocity, duration)
      pitches.each { |pitch| note_on(pitch, velocity) }
      @time += duration.to_i
      pitches.each { |pitch| note_off(pitch, velocity) }
    end
    
    def rest(duration)
      @time += duration.to_i
    end
    
  end

end

#Cosy::MidiRenderer.new.render 'TEMPO=60; e*4; TEMPO=120; d*8; TEMPO=240; c*16', 'test.mid'
# Cosy::MidiRenderer.new.render 'TEMPO=60; c4:q c c c:1/5q*5 c4:w', 'test.mid'
#Cosy::MidiRenderer.new.render '((G4 F4 E4 D4)*4 C4):(q. i):(p mf ff)', 'test.mid'
Cosy::MidiRenderer.new.render 'c -q d:q', 'test.mid'