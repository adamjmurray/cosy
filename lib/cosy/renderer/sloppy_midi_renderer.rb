require 'cosy/renderer/abstract_midi_renderer'

module Cosy

  class SloppyMidiRenderer < AbstractMidiRenderer

    DEFAULT_SCHEDULER_RATE = 0.005 # 5 milliseconds
    
    PLAYBACK_BUFFER = 1

    STOP_BUFFER = 2

    attr_accessor :scheduler_rate

    def initialize(options={})
      super
      @scheduler_rate = DEFAULT_SCHEDULER_RATE
      tempo(@tempo)
   end

    def play(timeline=@timeline,in_background=false) 
      start_scheduler
      @last_event_time = 0    
      @start_time = Time.now.to_f + PLAYBACK_BUFFER
      schedule_timeline(timeline)
      @scheduler.at(@last_event_time + STOP_BUFFER) { stop_scheduler } 
      thread = @scheduler.thread
      thread.join if not in_background
    end
    alias play render

    def absolute(time)
      @start_time + time/@ticks_per_sec
    end   

    def schedule(time, &block)
      time = absolute(time)
      @last_event_time = time if @last_event_time < time
      @scheduler.at(time) { block.call }
    end
    
    def tempo(tempo)
      # WARNING: this does not handle tempo changes properly
      # because we are converting to absolute time from the
      # current offset from beat 0 under the current tempo only
      @tempo = tempo
      @ticks_per_sec = @tempo/60.0 * DURATION['quarter']      
    end

    def start_scheduler
      @scheduler = MIDIator::Timer.new(@scheduler_rate) 
      Signal.trap("INT"){ stop_scheduler }
    end

    def stop_scheduler
      @scheduler.thread.exit!
    end

  end

end
