require 'cosy/renderer/abstract_midi_renderer'
require 'gamelan'

module Cosy

  class MidiRenderer < AbstractMidiRenderer

    TICKS_PER_BEAT = 480.0

    DEFAULT_SCHEDULER_RATE = 500 # Hz

    STOP_BUFFER = 2

    attr_accessor :scheduler_rate

    def initialize(options={})
      super
      @scheduler_rate = DEFAULT_SCHEDULER_RATE
      @scheduler = Gamelan::Scheduler.new
      @scheduler.tempo = @tempo
    end

    def render(timeline=@timeline, in_background=false) 
      @last_event_time = 0    
      schedule_timeline(timeline)
      @scheduler.at(@last_event_time + STOP_BUFFER) { @scheduler.stop } 
      thread = @scheduler.run
      thread.join if not in_background
    end
    alias play render

    def to_pulses(time)
      time / TICKS_PER_BEAT
    end   

    def schedule(time, &block)
      time = to_pulses(time)
      @last_event_time = time if @last_event_time < time
      @scheduler.at(time) { block.call }
    end

    def tempo(bpm)
      super
      @scheduler.tempo = bpm
    end
    
  end

end
