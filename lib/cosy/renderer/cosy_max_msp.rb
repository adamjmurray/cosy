# Requires:
# Max/MSP (http://cycling74.com)
# and ajm objects (http://compusition.com/web/software/maxmsp/ajm-objects)

# TODO
#==> Move ajm objects to github

require 'cosy'
include Cosy

module Cosy
  
  class MaxRenderer < AbstractRenderer  
    attr_accessor :seq, :time_to_next, :prev_duration, :end, :ticks_per_bang
  
    def initialize
      init
      parse ''
      @time_to_next = 1
      @end = false      
      @prev_duration = DURATION_NAME['sixtyfourth']
      @ticks_per_bang = DURATION_NAME['sixtyfourth'].to_f
    end

    def sequence(input)
      begin
        parse input
        restart
        return true
      rescue Exception
        error $!
        return false
      end
    end

    def restart
      init
      @sequencer.restart
      @time_to_next = 1
      @prev_duration = DURATION_NAME['sixtyfourth']
      @end = false
      @suppress_rebang = @rebang = false
    end
    
    # like restart but with inifinite loop prevention
    # should be used whenever automatically restarting at the end of a sequence
    def autorestart
      restart
      @suppress_rebang = @rebang
    end
    
    def ticks_to_bangs(ticks)
      ticks / @ticks_per_bang if ticks
    end

    def bang
      if not @end
        @time_to_next -= 1
        if @time_to_next <= 0
          event = next_event
          
          if not event
            @end = true
            out3 'bang'
          
          elsif event.is_a? NoteEvent
            pitches, velocity, duration = event.pitches, event.velocity, ticks_to_bangs(event.duration)
            if duration >= 0  
              # output in standard Max right-to-left order:
              out2 duration
              out1 velocity
              out0 pitches
              
              if duration == 0
                # prevent infinite loops
                if not @suppress_rebang
                  @rebang = true
                  bang
                else
                  @suppress_rebang = false
                end
              else
                @suppress_rebang = @rebang = false
              end
              
            end
            @time_to_next = duration.abs
          
          else
            error "Unsupported Event: #{event.inspect}"
          end
          
        end
      end
    end
    
  end
end

RENDERER = Cosy::MaxRenderer.new

################################################
# The interface for Max (the supported messages)

def sequence(input)
  out4 RENDERER.sequence(input)
end

def restart
  RENDERER.restart
end

def autorestart
  RENDERER.autorestart
end

def bang
  RENDERER.bang
end

