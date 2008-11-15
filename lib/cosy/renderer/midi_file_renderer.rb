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

        # Maybe these 2 cases are obsolete now?
        when Tempo then tempo(event.value)
        when Program then program(event.value)

        when NoteEvent
          pitches, velocity, duration = event.pitches, event.velocity, event.duration
          if duration >= 0
            notes(pitches, velocity, duration)
          else            
            rest(-duration)
          end
          
        else 
          if event.is_a? Chain
            if label = event.find{|e| e.is_a? Label}
              label = label.value.downcase
              values = event.find_all{|e| e.is_a? Numeric}
              value = values[0]
              if(not values.empty?)
                if TEMPO_LABELS.include? label
                  tempo(value)
                  next
                  
                elsif PROGRAM_LABELS.include? label
                  program(value)
                  next
                  
                elsif CHANNEL_LABELS.include? label
                  @channel = value
                  next
                  
                elsif CC_LABELS.include? label and values.length >= 2
                  cc(values[0],values[1])
                  next
                  
                elsif PITCH_BEND_LABELS.include? label
                  pitch_bend(value)
                  next
                end
                
              end
            end
          end
          
          raise "Unsupported Event: #{event.inspect}"
        end
      end
      
      # pad the end a bit, otherwise seems to cut off (TODO: make this optional)  
      @time += 480
      note_off(0, 0) 
      
      print_midi
      
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
          puts "#{event.to_s} (#{event.time_from_start})"
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
    
    def cc(controller, value)
      event = MIDI::Controller.new(@channel, controller.to_i, value.to_i)
      @track.insert(event, @time)
    end
    
    def pitch_bend(value)
      if value.is_a? Float
        # assume range -1.0 to 1.0
        # pitch bends go from 0 (lowest) to 16383 (highest) with 8192 in the center
        value = (value * 8191 + 8192).to_i # this will never give 0, oh well
      else
        value = value.to_i
      end
      event = MIDI::PitchBend.new(@channel, value)
      @track.insert(event, @time)
    end
  end

end

#Cosy::MidiRenderer.new.render 'c #cc:1:0 c #cc:0:127', 'test.mid'
#Cosy::MidiRenderer.new.render 'c #pb:1.0 c #pb:-1.0 c #pb:0.0 c', 'test.mid'
#Cosy::MidiRenderer.new.render '#tempo:60 e*4 120:#tempo b3*8 #tempo:240 c4*16', 'test.mid'
#Cosy::MidiRenderer.new.render 'TEMPO=60; e*4; TEMPO=120; d*8; TEMPO=240; c*16', 'test.mid'
# Cosy::MidiRenderer.new.render 'TEMPO=60; c4:q c c c:1/5q*5 c4:w', 'test.mid'
#Cosy::MidiRenderer.new.render '((G4 F4 E4 D4)*4 C4):(q. i):(p mf ff)', 'test.mid'
#Cosy::MidiRenderer.new.render 'c -i d', 'test.mid'