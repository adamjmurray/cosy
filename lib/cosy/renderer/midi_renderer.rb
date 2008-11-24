require 'rubygems'
require 'midiator'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require cosy_root

module Cosy
  
  class MidiRenderer < AbstractRenderer  

    # TODO: time for some refactoring with the MidiFileRenderer
    # too much duplicated logic here
    
    # Time to wait in seconds, before starting playback
    # It's a good idea to have a buffer so the first note doesn't start late.
    def self.DEFAULT_PLAYBACK_BUFFER; 1 end
    
    # Default sleep time in between the scheduler servicing events.
    def self.DEFAULT_SCHEDULER_RATE; 0.005 end # 5 milliseconds

    attr_accessor :playback_buffer, :scheduler_rate

    def initialize(driver=nil)
      super()
      
      if not defined? @@midi
        @@midi = MIDIator::Interface.new
        if driver
          @@midi.use(driver)
        else
          @@midi.autodetect_driver
        end
        at_exit { @@midi.close }
      end
      
      @channel = 0
      @time = 0
      tempo(120)
      
      @playback_buffer = MidiRenderer.DEFAULT_PLAYBACK_BUFFER
      @scheduler_rate = MidiRenderer.DEFAULT_SCHEDULER_RATE
    end

    def start_scheduler
      if not @scheduler
        @scheduler = MIDIator::Timer.new(@scheduler_rate) 
        Signal.trap("INT"){ stop_scheduler }
      end
    end
      
    def stop_scheduler
      @scheduler.thread.exit! if @scheduler
      @cheduler = nil
    end

    def render(input)    
      parse input
      start_scheduler

      @start_time = Time.now.to_f + @playback_buffer
      while event = next_event
        case event

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
            end
          end

          raise "Unsupported Event: #{event.inspect}"
        end
      end
      rest(960) # pad the end a bit (make configurable?)
      add_event { stop_scheduler }
      @scheduler.thread.join
    end
    alias play render
    
    #################
    private
    
    def add_event(&block)
      @scheduler.at(@start_time + @time/@ticks_per_sec, &block)
    end

    # Set tempo in terms of Quarter Notes per Minute (aka BPM)
    def tempo(qnpm)
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
      @time += duration
      pitches.each { |pitch| note_off(pitch, velocity) }
    end

    def rest(duration)
      @time += duration
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

