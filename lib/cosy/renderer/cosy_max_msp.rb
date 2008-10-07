# Requires:
# Max/MSP (http://cycling74.com)
# and ajm objects (http://compusition.com/web/software/maxmsp/ajm-objects)

# TODO
#==> Need a Max help file for this.
#==> Move ajm objects to github


require 'cosy'
include Cosy

module Cosy
  
  class MaxRenderer < AbstractRenderer  
    attr_accessor :seq, :time_to_next, :prev_duration, :end, :ticks_per_bang
  
    def initialize
      init
      @seq = Sequencer.new('')
      @time_to_next = 1
      @end = false      
      @prev_duration = DURATION['sixtyfourth']
      @ticks_per_bang = DURATION['sixtyfourth'].to_f
    end

    def set(input)
      @seq = Sequencer.new(input)
      restart
      return !@seq.tree.nil?
    end

    def restart
      init
      @seq.restart if @seq
      @time_to_next = 1
      @prev_duration = DURATION['sixtyfourth']
      @end = false
    end
    
    def ticks_to_bangs(ticks)
      ticks / @ticks_per_bang if ticks
    end

    def bang
      if @seq and not @end
        @time_to_next -= 1
        if @time_to_next <= 0
          event = @seq.next
          if not event
            @end = true
            out3 'bang'
          else
            pitches, velocity, duration = getPitchesVelocityDuration(event)    
            duration = ticks_to_bangs(duration)
            if duration >= 0  
              # output in standard Max right-to-left order:
              out2 duration
              out1 velocity
              out0 pitches
              @time_to_next = duration
              if duration == 0
                # TODO !! : prevent infinite loops
                bang
              end
            else
              @time_to_next = duration.abs
            end
          end
        end
      end
    end
  end
end

$Renderer = Cosy::MaxRenderer.new

def seq input
  out4 $Renderer.set(input)
end

def restart
  $Renderer.restart
end

def bang
  $Renderer.bang
end

