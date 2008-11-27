require 'midiator'

module Cosy

  class MidiRenderer < AbstractRenderer  

    # TODO: time for some refactoring with the MidiFileRenderer
    # too much duplicated logic here

    # Time to wait in seconds, before starting playback
    # It's a good idea to have a buffer so the first note doesn't start late.
    def self.DEFAULT_PLAYBACK_BUFFER; 0.5 end

    # Default sleep time in between the scheduler servicing events.
    def self.DEFAULT_SCHEDULER_RATE; 0.005 end # 5 milliseconds

    attr_accessor :playback_buffer, :scheduler_rate

    def initialize(options)
      super(options)

      if not defined? @@midi
        @@midi = MIDIator::Interface.new
        driver = options[:driver]
        if driver
          @@midi.use(driver)
        else
          @@midi.autodetect_driver
        end
        at_exit { @@midi.close }
      end

      @parent = options[:parent]
      if @parent
        @scheduler = @parent.scheduler
        @start_time = @parent.start_time
      else
        # don't need to inherit these from the parent since
        # the schedulerer is inherited
        @playback_buffer = MidiRenderer.DEFAULT_PLAYBACK_BUFFER
        @scheduler_rate = MidiRenderer.DEFAULT_SCHEDULER_RATE
      end
      
      @time = options[:time] || 0
      @channel = options[:channel] || 0
      self.tempo = options[:tempo] || 120
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

    def start_scheduler
      if not @scheduler
        @scheduler = MIDIator::Timer.new(@scheduler_rate) 
        Signal.trap("INT"){ stop_scheduler }
      end
    end

    def stop_scheduler
      @scheduler.thread.exit! if @scheduler
      @scheduler = nil
    end

    def render()    
      start_scheduler
      @start_time = Time.now.to_f + @playback_buffer if not @start_time
      
      loop do
        event = next_event
        case event
        when nil
          break

        when ParallelSequencer
          stop_time = @time
          event.each do |sequencer|
            renderer = MidiRenderer.new(clone_state(sequencer))
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

        when Chain
          if label = event.find{|e| e.is_a? Label}
            label = label.value.downcase
            values = event.find_all{|e| e.is_a? Numeric}
            value = values[0]
            if(not values.empty?)
              if TEMPO_LABELS.include? label
                self.tempo = value
                next

              elsif PROGRAM_LABELS.include? label
                program(value)
                next

              elsif CHANNEL_LABELS.include? label
                @channel = value-1 # I count channels starting from 1, but MIDIator starts from 0
                next

              elsif CC_LABELS.include? label and values.length >= 2
                cc(values[0],values[1])
                next

              elsif PITCH_BEND_LABELS.include? label
                pitch_bend(value)
                next
              end

            end
          else
            raise "Unsupported Event: #{event.inspect}"
          end
        end
      end

      if not @parent # else we're in a child sequence and this code should not run
        rest(960) # pad the end a bit (make configurable?)
        add_event { stop_scheduler }
        @scheduler.thread.join
      end
    end
    
    alias play render
    
    
    #################
    protected

    def time
      @time
    end
    
    def scheduler
      @scheduler
    end
    
    def start_time
      @start_time
    end
    

    #################
    private

    def add_event(&block)
      @scheduler.at(absolute_time, &block)
    end
    
    def absolute_time
      @start_time + @time
    end
    
    def advance_time(duration_in_ticks)
      @time += duration_in_ticks/@ticks_per_sec
    end

    # Set tempo in terms of Quarter Notes per Minute (aka BPM)
    def tempo=(qnpm)
      @tempo = qnpm
      @ticks_per_sec = qnpm/60.0 * DURATION['quarter']
    end

    def program(program_number)
      add_event { @@midi.program_change(@channel, program_number) }
    end

    def note_on(pitch, velocity)
      add_event { @@midi.note_on(pitch.to_i, @channel, velocity.to_i) }
    end

    def note_off(pitch, velocity)
      add_event { @@midi.note_off(pitch.to_i, @channel, velocity.to_i) }
    end

    def notes(pitches, velocity, duration)
      pitches.each { |pitch| note_on(pitch, velocity) }
      advance_time duration
      pitches.each { |pitch| note_off(pitch, velocity) }
    end

    def rest(duration)
      advance_time duration
    end

    def cc(controller, value)
      add_event { @@midi.control_change(controller.to_i, @channel, value.to_i) }
    end

    def pitch_bend(value)
      # TODO refactor this logic
      if value.is_a? Float
        # assume range -1.0 to 1.0
        # pitch bends go from 0 (lowest) to 16383 (highest) with 8192 in the center
        value = (value * 8191 + 8192).to_i # this will never give 0, oh well
      else
        value = value.to_i
      end
      add_event { @@midi.pitch_bend(@channel, value) }
    end

  end
end
