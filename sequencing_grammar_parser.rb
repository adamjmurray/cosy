require 'rubygems'
require 'treetop'
require 'sequencing_grammar'
include Treetop::Runtime

PITCH_CLASS = {
  'C'=>0, 'C#'=>1, 'D'=>2, 'D#'=>3, 'E'=>4, 'F'=>5,'F#'=>6, 
  'G'=>7, 'G#'=>8, 'A'=>9, 'A#'=>10, 'B'=>11
}
OCTAVE_OFFSET = 1  

  
INTENSITY = {
  'ppp'=>15, 'pp'=>31, 'p'=>47, 'mp'=>63, 
  'mf'=>79, 'f'=>95, 'ff'=>111, 'fff'=>127    
}


DURATION = {
  'x'=>1, 'r'=>2, 's'=>4, 'e'=>8, 'q'=>16, 'h'=>32, 'w'=>64
}


class SyntaxNode
  
  def children
    @children = [] if not @children
    @children
  end
    
  def visit_parse_tree(enter,exit=nil)
    if enter.call(self) then
      elements.each{ |child| child.visit_parse_tree(enter,exit) } if nonterminal?
      exit.call(self) if exit
    end  
  end
  
  def visit(enter,exit=nil)
    if enter.call(self) then
      children.each{ |child| child.visit(enter,exit) } if nonterminal?
      exit.call(self) if exit
    end  
  end
  
  def empty?
    text_value.strip.size == 0 
  end
    
  def value
    @value = text_value.strip if not @value
    @value
  end
    
  def evaluate
    @value = text_value.strip
    start
  end
  
  def start
    @start = true
  end

  def next?
    false
  end

  def next
    nil
  end

  def to_s
    text_value.strip
  end
  
  def inspect
    "#{self.class} #{value}"
  end
end

class SequencingNode < SyntaxNode
end

class GeneratorNode < SequencingNode
  def next?
    # The basic generator holds exactly one value
    # so there is a value to output if and only if we're at the start
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


class TerminalNode < GeneratorNode
  def nonterminal?
    false
  end
  def terminal?
    true
  end
end



class ContainerNode < GeneratorNode   
  def children
    if not @children
      @children = []
      visit_parse_tree(lambda do |node|
        if node != self and node.is_a? SequencingNode then
          if (node.terminal? or node.children.size > 1) then
            @children << node
            return false
          end
        end
        # else keep descending:
        return true 
      end)
    end

    @children
  end
  
  def to_s
    children.join(' ')
  end
end


class SequenceNode < ContainerNode
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

class ChoiceNode < ContainerNode
  def to_s
    children.join(' | ')
  end

end

class ChainNode < ContainerNode
  attr :repetitions  # supports fractional repetitions!

  def next?
    return false if @repetitions <= 0
    if @limited then
      return (@subseq.next? or @repetitions > @index+1)
    else
      return (@subseq.next? or @value.length*@repetitions > @index+1)
    end
  end

  def evaluate
    super
    if modifier.elements then
      modifier.evaluate
      @operator = modifier.operator.text_value.strip
      @limited = (@operator == '&')
    
      repetitions = modifier.operand
      #@repetitions = repetitions.evaluate
      # To support Ruby (I don't like this, how can I clean it up?)
      repetitions.evaluate
      repetitions.start
      @repetitions = repetitions.next

#      puts "OPERATOR is '#@operator', limited=#@limited, reps=#@repetitions"

    else
      @operator = nil
      @repetitions = 1
      @limited = false
    end
  end

  def to_s
    s = children.join(':')
    s += "#@operator#@repetitions" if @operator
    s
  end    
end

class ParenthesizedNode < GeneratorNode
  def evaluate
    subsequence.evaluate
  end
  
  def to_s
    s = "(#{subsequence})"
  end
end

class ModifierNode < ContainerNode
  
end

class OperatorNode < TerminalNode
  
end

class ChordNode < ContainerNode 
  # def evaluate
  #   super
  #   @value.map!{|v| v.value}
  # end
  
  def to_s
    "[#{super}]"
  end
end

class NoteNode < TerminalNode
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

  # def to_s
  #     "#{text_value}=#@value"
  #   end
end

TWO_THIRDS = 2/3.0

class DurationNode < TerminalNode
  def evaluate
    @value = DURATION[metrical_duration.text_value.downcase]
    if(multiplier.text_value != '') then
      @value *= multiplier.to_i # TODO use to_f if appropriate
    end
    modifier.text_value.each_byte do |bytes|
      case byte.chr
      when 't'; @value *= TWO_THIRDS
      when '.'; @value *= 1.5
      end
    end
  end  
end

class VelocityNode < TerminalNode
  def evaluate
    @value = INTENSITY[text_value.downcase]  
  end
end

class FloatNode < TerminalNode
  def evaluate
    @value = text_value.to_f
  end
end


class IntNode < TerminalNode
  def evaluate
    @value = text_value.to_i
  end
  
  def terminal?
    true
  end
end


class StringNode < TerminalNode
end


class RubyNode < TerminalNode
  def evaluate
    @value = eval script.text_value
  end
  
  def next
    if next? then 
      @start = false
      eval @value
    else 
      nil 
    end
  end  
  
end


class SequencingGrammarParser
  # force an evaluation step after parsing:
  alias orig_parse parse
  def parse(*args)
    parse_tree = orig_parse(*args)
    if parse_tree then
      # strip off unnecessary container nodes
      if parse_tree.nonterminal? and parse_tree.children.size == 1 then
        parse_tree = parse_tree.children[0]
      end
      # print_tree parse_tree
    end
    return parse_tree
  end
  
  def parse_verbose input
    puts "PARSING: #{input}"
    output = parse input
    if output
      puts 'success'
    else
      puts 'failure'
    end
    print_tree output
    puts
    return output
  end
  
  def remove_empty_nodes tree
    tree.visit_parse_tree(lambda do |node|
      if node.class == ChoiceNode
        puts 'CHOICE' + node.text_value
        puts node.first.text_value
        puts "'" + node.rest.text_value + "'"
                puts node.children.inspect
      end

      children = node.elements
      if children then
        children.each_with_index do |elem,idx|
          children.delete_at(idx) if elem.empty? 
        end
      end
    end)
  end
  
  def print_parse_tree tree
    depth = 0
    tree.visit_parse_tree(lambda do |node|
      depth.times{print '    '}
      puts node.inspect
      depth += 1
    end,
    lambda do |node| # exit
      depth -= 1
    end)
  end

  def print_tree tree
    depth = 0
    tree.visit(lambda do |node|
      depth.times{print '    '}
      puts node.inspect
      depth += 1
    end,
    lambda do |node| # exit
      depth -= 1
    end)
  end
  
  def single_item_container? node
    (node.class == ChoiceNode and empty? node.rest) 
    (node.class == ChainNode and node.rest.text_value.strip.size == 0) 
  end
     
  
end

# SequencingGrammarParser.new.parse_verbose '(1 2 3)&4 ([C4 G4]:mf:q (C4:f:e | G4:f:s*2)) * 2.5  (1 2 3):(4 5 6)'


SequencingGrammarParser.new.parse_verbose '(1 2):(3 4)*2 ((1 2)*2):(3 4)'



