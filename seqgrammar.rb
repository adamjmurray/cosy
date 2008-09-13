require 'sequencer'

$seq = Sequencer.new ''

def seq input
  #puts "parsing input: #{input}"
  $seq = Sequencer.new(input)
  #puts "parsed #{$seq}"
  out4 !$seq.tree.nil?
end

def restart
  $seq.restart if $seq
end

def bang
  if $seq
    val = $seq.next
    if val
      if val.is_a? Array
        out2 val[2] if val[2]
        out1 val[1] if val[1]
        out0 val[0] if val[0]
      else
        out0 val
      end
      return
    end
  end
  out3'bang'
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