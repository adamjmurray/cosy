# Requires:
# Max/MSP (http://cycling74.com)
# and ajm objects (http://compusition.com/web/software/maxmsp/ajm-objects)

# TODO
#==> Loading this script in Max fails the first time, don't know why yet.
#       Either caused by JRuby 1.4 or my recent changes to ajm.ruby
#       Need to investigate!
#       Workaround is to delete the object and undo, then it loads succesfully.
#==> Need a Max help file for this.
#==> Move ajm objects to github

require 'cosy'
include Cosy

$seq = Sequencer.new ''
$time_to_next = 1
$prev_duration = 1
$end = false

$ticks_per_bang = DURATION['sixtyfourth']

def seq input
  $seq = Sequencer.new(input)
  restart
  out4 !$seq.tree.nil?
end

def restart
  $seq.restart if $seq
  $time_to_next = $prev_duration = 1
  $end = false
end

def ticks_to_bangs(ticks)
  ticks / 30 if ticks # a 64th note is the smallest resolution I am supporting right now, that is 30 ticks
end

def bang
  if $seq and not $end
    $time_to_next -= 1
    if $time_to_next <= 0
      val = $seq.next
      if not val
        $end = true
        out3 'bang'
      else
        if val.is_a? Chain
          note = val[0]
          duration = ticks_to_bangs(val[1])
          velocity = val[2]
        else
          note = val
        end
        
        if not duration
          duration = $prev_duration
        end
        $time_to_next = $prev_duration = duration
        
        if duration >= 0  
          # output in standard Max right-to-left order:
          out2 duration
          out1 velocity if velocity
          out0 note
          if duration == 0
            # TODO: prevent infinite loops
            bang
          end
        else
          $time_to_next = $time_to_next.abs
        end
      end
    end
  end
end
