require 'cosy/helper/midi_file_renderer_helper'

module Cosy

  class MidiFileRenderer < AbstractRenderer
    attr_reader :midi_sequence

    def initialize(options={})
      super

      @channel = options[:channel] || 1
      @time = options[:time] || 0
      @output = options[:output]
      raise ':output must be specified in constructor options' if not @output
      @midi_sequence = MIDI::Sequence.new() 
      @meta_track = @midi_sequence.create_track('Cosy Sequence')
      @track = @midi_sequence.create_track('Track 1')
      tempo(options.fetch(:tempo, 120))
      program(options.fetch(:program, 0))
    end
    
    def render(timeline=@timeline)
      timeline.each_event do |time,event|
        if event.respond_to? :channel
          channel = event.channel
        end
        @channel = channel ||= @channel 
        @time = time
        
        case event
        when Event::Note
          pitch,velocity,duration = event.pvdc
          note_on(pitch, velocity)
          @time += duration
          note_off(pitch, velocity)
          
        when Event::ProgramChange
          program(event.program_number)
        
        when Event::PitchBend
          pitch_bend(event.midi)
          
        when Event::ControlChange
          cc(event.controller_number, event.value)
            
        when Event::Tempo
          tempo(event.bpm)
        
        else
          unhandled_event(time,event)
        end
      end
      
       # pad the end a bit, otherwise seems to cut off (TODO: make this optional)  
        @time += 480
        note_off(0, 0) 

        @meta_track.recalc_delta_from_times
        @track.recalc_delta_from_times

        print_midi if $DEBUG
        File.open(@output, 'wb') { |file| @midi_sequence.write(file) }
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
    

    # Set tempo in terms of Quarter Notes per Minute (aka BPM)
    def tempo(bpm)
      # if @parent then this is a child sequence and we should respect
      # the parent tempo and adjust the qnpm accordingly
      @tempo = bpm
      ms_per_quarter_note = MIDI::Tempo.bpm_to_mpq(bpm)
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

    def cc(controller, value)
      event = MIDI::Controller.new(@channel, controller.to_i, value.to_i)
      @track.insert(event, @time)
    end

    def pitch_bend(value)
      event = MIDI::PitchBend.new(@channel, value)
      @track.insert(event, @time)
    end
  end
 
end
