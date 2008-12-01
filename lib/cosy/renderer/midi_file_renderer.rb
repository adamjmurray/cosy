require 'midilib'

# First we need to add some API infrastructure:
class Array
  # This code borrowed from 'Moser' http://codesnippets.joyent.com/posts/show/1699
  
  # A stable sorting algorithm that maintains the relative order of equal elements
  def mergesort(&cmp)
    if cmp == nil
      cmp = lambda { |a, b| a <=> b }
    end
    if size <= 1
      self.dup
    else
      halves = split.map{ |half|
        half.mergesort(&cmp)
      }
      merge(*halves, &cmp)
    end
  end

  protected
  def split
    n = (length / 2).floor - 1
    [self[0..n], self[n+1..-1]]
  end

  def merge(first, second, &predicate)
    result = []
    until first.empty? || second.empty?
      if predicate.call(first.first, second.first) <= 0
        result << first.shift
      else
        result << second.shift
      end 
    end
    result.concat(first).concat(second)
  end
end

module MIDI
  class Track
    def insert(event, time) 
      event.time_from_start = time
      events << event
      return event
    end

    # Redefine recalc method to use a stable mergesort instead of the default sort
    # (otherwise this method should be the same as the original source,
    #  which was true as of Midilib 1.0.0)
    def recalc_delta_from_times(starting_at=0, list=@events)
      prev_time_from_start = 0
      # We need to sort the sublist. sublist.sort! does not do what we want.
      list[starting_at .. -1] = list[starting_at .. -1].mergesort { | e1, e2 |
        e1.time_from_start <=> e2.time_from_start
      }
      list[starting_at .. -1].each { | e |
        e.delta_time = e.time_from_start - prev_time_from_start
        prev_time_from_start = e.time_from_start
      }
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


# And now the actual implementation
module Cosy

  class MidiFileRenderer < AbstractRenderer
    attr_reader :midi_sequence

    def initialize(options)
      super(options)

      @channel = options[:channel] || 1
      @time = options[:time] || 0

      @parent = options[:parent]
      if @parent
        @meta_track = @parent.meta_track
        @track = @parent.track
      else
        @output = options[:output]
        raise ':output must be specified in constructor options' if not @output
        @midi_sequence = MIDI::Sequence.new() 
        @meta_track = @midi_sequence.create_track('Cosy Sequence')
        @track = @midi_sequence.create_track('Track 1')
        tempo(120)
        program(0)
      end
    end

    def clone_state(input)
      {
        :input => input,
        :parent => self,
        :time => @time,
        :channel => @channel,
        :tempo => @tempo
      }
    end

    def render()
      while event = next_event
        case event

        when ParallelSequencer
          stop_time = @time
          event.each do |sequencer|
            renderer = MidiFileRenderer.new(clone_state(sequencer))
            renderer.render
            stop_time = renderer.time if renderer.time > stop_time
          end
          @time = stop_time
          next  

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

      if not @parent
        # pad the end a bit, otherwise seems to cut off (TODO: make this optional)  
        @time += 480
        note_off(0, 0) 

        @meta_track.recalc_delta_from_times
        @track.recalc_delta_from_times

        print_midi if $DEBUG
        File.open(@output, 'wb') { |file| @midi_sequence.write(file) }
      end
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
    protected
    
    def time
      @time
    end
    
    def meta_track
      @meta_track
    end
    
    def track
      @track
    end
    

    ############
    private  

    # Set tempo in terms of Quarter Notes per Minute (aka BPM)
    def tempo(qnpm)
      # if @parent then this is a child sequence and we should respect
      # the parent tempo and adjust the qnpm accordingly
      @tempo = qnpm
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
