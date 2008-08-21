require 'rubygems'
require 'treetop'
require 'sequencing_grammar'

PITCH_CLASS = {
  'C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4, 'F'=>5,'F#'=>6, 
  'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11
}
OCTAVE_OFFSET = 1  


class Treetop::Runtime::SyntaxNode
  def visit(enter,exit=nil)
    if enter.call(self) then
      elements.each{ |child| child.visit(enter,exit) } if nonterminal?
      exit.call self if exit
    end  
  end

  attr :value   
  def evaluate
    @value = text_value
  end

  def to_s
    text_value
  end
  
  def inspect
    value.inspect
  end
end


class GeneratorNode < Treetop::Runtime::SyntaxNode
  def start
    @start = true
  end

  def next?
    @start
  end

  def next
    if next? then 
      @start = false
      @value 
    else 
      nil 
    end
  end
end


class ContainerNode < GeneratorNode  
  def children
    return elements
  end

  def to_s
    @value.join(' ')
  end

  def evaluate
    @value = []
    children.each do |c|
      c.visit(proc do |node|
        if node.is_a? GeneratorNode then
          @value << node
          node.evaluate
          false
        else # keep descending
          true
        end
      end)
    end
  end
end


class SeqNode < ContainerNode
  def start
    @index = 0
    @subseq = @value[0]
    @subseq.start
  end

  def next?
    return (@subseq.next? or @value.length > @index+1)
  end

  def next
    if not @subseq.next?
      @index += 1
      @subseq = @value[@index % @value.length]
      @subseq.start
    end
    return @subseq.next
  end
end


class RepetitionNode < SeqNode
  attr :repetitions  # supports fractional repetitions!

  def next?
    return (@subseq.next? or @value.length*@repetitions > @index+1)
  end

  def children
    if defined? subseq then
      subseq.elements 
    else
      [value]
    end
  end

  def evaluate
    super
    @repetitions = repetitions.evaluate
  end

  def to_s
    "(#{super})*#@repetitions"
  end  
end


class ChordNode < ContainerNode 
  def to_s
    "[#{super}]"
  end
end


class NoteNode < GeneratorNode
  def evaluate
    @value = PITCH_CLASS[note_name.text_value.upcase]
    accidentals.text_value.each_byte do |byte|
      case byte.chr
      when '#'; @value += 1
      when 'b'; @value -= 1
      when '+'; @value += 0.5
      when '_'; @value -= 0.5 
      end
    end
    @value += 12*(octave.evaluate+OCTAVE_OFFSET)
  end

  def to_s
    "#{text_value}=#@value"
  end
end


class FloatNode < GeneratorNode
  def evaluate
    @value = text_value.to_f
  end
end


class IntNode < GeneratorNode
  def evaluate
    @value = text_value.to_i
  end
end


class SequencingGrammarParser
  # force an evaluation step after parsing:
  alias orig_parse parse
  def parse(*args)
    parse_tree = orig_parse(*args)
    parse_tree.evaluate if parse_tree
    return parse_tree
  end
end





