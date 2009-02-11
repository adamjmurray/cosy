require 'midiator'
require 'gamelan'

module Cosy

  class MidiGamelanRenderer < AbstractRenderer  

    # TODO: time for some refactoring with the MidiFileRenderer
    # too much duplicated logic here

    TICKS_PER_BEAT = 480.0

    def self.DEFAULT_SCHEDULER_RATE; 1000 end # 1000 Hz

    attr_accessor :scheduler_rate

    def initialize(options)
      super(options)
      
      if not defined? $MIDI
        $MIDI = MIDIator::Interface.new
        driver = options[:driver]
        if driver
          $MIDI.use(driver)
        else
          $MIDI.autodetect_driver
        end
        @@held_notes = Hash.new do |hash,key| hash[key] = {} end
        
        at_exit do
          @@held_notes.each do |channel,note_hash|
            note_hash.each do |pitch,velocity|
              $MIDI.note_off(pitch, channel, velocity)
            end
          end
          $MIDI.close 
        end
      end
      
      @parent = options[:parent]
      if @parent
        @scheduler = @parent.scheduler
        @start_time = @parent.start_time
      else
        # don't need to inherit these from the parent since
        # the schedulerer is inherited
        @scheduler_rate = MidiGamelanRenderer.DEFAULT_SCHEDULER_RATE
        @scheduler = Gamelan::Scheduler.new
      end
      
      @time = options[:time] || 0
      @channel = options[:channel] || 0
      tempo(options[:tempo] || 120)
    end

    def render()    
      loop do
        event = next_event
        case event
        when nil
          break

        when ParallelSequencer
          stop_time = @time
          event.each do |sequencer|
            renderer = self.class.new(clone_state(sequencer))
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
          next

        when Chain
          first_value = event.first
          values = event[1..-1]
          case first_value
          when Label
            label = first_value.value.downcase            
            value = values[0]
            if TEMPO_LABELS.include? label and value
              tempo(value)
              next
            elsif PROGRAM_LABELS.include? label and value
              program(value)
              next
            elsif CHANNEL_LABELS.include? label and value
              @channel = value-1 # I count channels starting from 1, but MIDIator starts from 0
              next
            elsif CC_LABELS.include? label and values.length >= 2
              cc(values[0],values[1])
              next
            elsif PITCH_BEND_LABELS.include? label and value
              pitch_bend(value)
              next
            elsif label == OSC_HOST_LABEL and value
              osc_host(value)
              next  
            elsif label == OSC_PORT_LABEL and value
              osc_port(value)
              next
            end
            
          when OscAddress
            osc(first_value, values)
            next    
          end
        end # Chain case
        
        STDERR.puts "Unsupported Event: #{event.inspect}"
      end

      if not @parent # else we're in a child sequence and this code should not run
        @scheduler.at(@time + 2) { @scheduler.stop } # schedule shutdown, after a little extra time
        @scheduler.run.join
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
    
    def clone_state(input)
      {
        :input => input,
        :parent => self,
        :time => @time,
        :channel => @channel,
        :tempo => @tempo
      }
    end

    def add_event(&block)
      @scheduler.at(@time, &block)
    end
    
    def advance_time(duration_in_ticks)
      @time += duration_in_ticks/TICKS_PER_BEAT # TODO: use ratios?
    end

    # Set tempo in terms of Quarter Notes per Minute (aka BPM)
    def tempo(qnpm)
      @tempo = qnpm 
      add_event { @scheduler.tempo = qnpm }
    end

    def program(program_number, channel=@channel)
      add_event { $MIDI.program_change(channel, program_number) }
    end

    def note_on(pitch, velocity, channel=@channel)
      add_event do
        $MIDI.note_on(pitch.to_i, channel, velocity.to_i)
        @@held_notes[@channel][pitch] = velocity
      end
    end

    def note_off(pitch, velocity, channel=@channel)
      add_event do
        $MIDI.note_off(pitch.to_i, channel, velocity.to_i)
        @@held_notes[@channel].delete pitch
      end
    end

    def notes(pitches, velocity, duration, channel=@channel)
      pitches.each { |pitch| note_on(pitch, velocity, channel) }
      advance_time duration
      pitches.each { |pitch| note_off(pitch, velocity, channel) }
    end

    def rest(duration)
      advance_time duration
    end

    def cc(controller, value, channel=@channel)
      add_event { $MIDI.control_change(controller.to_i, channel, value.to_i) }
    end

    def pitch_bend(value, channel=@channel)
      # TODO refactor this logic
      if value.is_a? Float
        # assume range -1.0 to 1.0
        # pitch bends go from 0 (lowest) to 16383 (highest) with 8192 in the center
        value = (value * 8191 + 8192).to_i # this will never give 0, oh well
      else
        value = value.to_i
      end
      add_event { $MIDI.pitch_bend(channel, value) }
    end
    
    def osc_host(hostname)
      osc_warning
    end
    
    def osc_port(port)
      osc_warning
    end
    
    def osc(address, args) 
      osc_warning
    end

    def osc_warning
      STDERR.puts "OSC not supported by this renderer" if not @warned_about_osc
      @warned_about_osc = true      
    end
    
  end
  
end
