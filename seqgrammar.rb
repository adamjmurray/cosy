require 'sequencer'

$seq = Sequencer.new ''
$time_to_next = 1
$prev_duration = 1
$end = false

def seq input
  #puts "parsing input: #{input}"
  $seq = Sequencer.new(input)
  restart
  #puts "parsed #{$seq}"
  out4 !$seq.tree.nil?
end

def restart
  $seq.restart if $seq
  $time_to_next = $prev_duration = 1
  $end = false
end

def bang
  if $seq and not $end
    # puts "here #$time_to_next"
    $time_to_next -= 1
    if $time_to_next <= 0
      val = $seq.next
      if not val
        $end = true
        out3 'bang'
      else
        if val.is_a? Array and not val.is_a? Chord
          note = val[0]
          duration = val[1]
          velocity = val[2]
        else
          note = val
        end
        
        if not duration
          duration = $prev_duration
        end
        $time_to_next = $prev_duration = duration
          
        # output in standard Max right-to-left order:
        out2 duration
        out1 velocity if velocity
        out0 note
      end
    end
  end
end
# 
# def out0 args
#   puts args
# end
# def out1 args
#   puts args
# end
# def out2 args
#   puts args
# end
# 
# seq '1 2 3'
# bang
# bang