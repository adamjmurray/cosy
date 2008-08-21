require 'sequencing_grammar_parser'

PARSER = SequencingGrammarParser.new

def seq input
  $gen = nil
  $gen = PARSER.parse input
  if $gen then
    restart
    out2 true
  else
    out2 false
  end
end

def restart
  $gen.start if $gen
end

def bang
  if $gen and $gen.next?
    out0 $gen.next
  else
    out1 'bang'
  end
end
