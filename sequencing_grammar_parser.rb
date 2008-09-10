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
  
  alias syntax_parent parent # the post parsing step will "compress" the tree and redefine parent
  
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
  
  def children
    @children = [] if not @children
    return @children
  end
    
  def value
    @value = text_value.strip if not @value
    return @value
  end
  
  def empty?
    value.length == 0 
  end

  def length
    if not @length then
      @length = (empty? ? 0 : 1)
    end
    return @length
  end
  def size
    length
  end
  
  def to_s
    text_value
  end
  
  def inspect
    "#{self.class} '#{text_value.strip}'"
  end
  
  def single_value?
    false
  end
end

class SequencingNode < SyntaxNode

  # def inspect
  #   super + "  (#{size})"
  # end
end

class GeneratorNode < SequencingNode
  # def next?
  #   # The basic generator holds exactly one value
  #   # so there is a value to output if and only if we're at the start
  #   @start
  # end
  # 
  # def next
  #   if next? then 
  #     @start = false
  #     @value 
  #   else 
  #     nil 
  #   end
  # end
end


class TerminalNode < GeneratorNode
  def nonterminal?
    false
  end
  def terminal?
    true
  end
  def single_value?
    true
  end
end


class ContainerNode < GeneratorNode   
  def children
    if not @children
      @children = []
      visit_parse_tree(lambda do |node|
        if node != self and node.is_a? SequencingNode and (node.terminal? or node.children.size > 1) then
          @children << node
          return false
        end
        # else keep descending:
        return true 
      end)
    end
    return @children
  end
  
  def value
    children
  end
  
  def length
    value.length
  end
  
  def [] index
    value[index]
  end
end


class SequenceNode < ContainerNode

  # def start
  #   @index = 0
  #   @subseq = @value[0]
  #   @subseq.start
  # end
  # 
  # def next?
  #   return (@subseq.next? or @value.length > @index+1)
  # end
  # 
  # def next
  #   if not @subseq.next?
  #     @index += 1
  #     @subseq = @value[@index % @value.length]
  #     @subseq.start
  #   end
  #   return @subseq.next
  # end
end

class ChoiceNode < ContainerNode

end

class ChainNode < ContainerNode
  attr :repetitions  # supports fractional repetitions!
# 
#   def next?
#     return false if @repetitions <= 0
#     if @limited then
#       return (@subseq.next? or @repetitions > @index+1)
#     else
#       return (@subseq.next? or @value.length*@repetitions > @index+1)
#     end
#   end
# 
#   def evaluate
#     super
#     if modifier.elements then
#       modifier.evaluate
#       @operator = modifier.operator.text_value.strip
#       @limited = (@operator == '&')
#     
#       repetitions = modifier.operand
#       #@repetitions = repetitions.evaluate
#       # To support Ruby (I don't like this, how can I clean it up?)
#       repetitions.evaluate
#       repetitions.start
#       @repetitions = repetitions.next
# 
# #      puts "OPERATOR is '#@operator', limited=#@limited, reps=#@repetitions"
# 
#     else
#       @operator = nil
#       @repetitions = 1
#       @limited = false
#     end
#   end
  def operand
    eval_operand if not @operand
    return @operand
  end
  
  def eval_operand
    if not modifier.empty?
      @operand = modifier.operand.value
    else
      @operand = 1
    end
  end

  def single_value?
    value if not @value
    return @single_value
  end

  def value
    if not @value then
      @value = Array.new children
      @value.pop if @value.last.class == ModifierNode
      if @value.all?{|child| child.single_value?} then
        @single_value = true
        @value = @value.collect{|child| child.value}
      else
        @single_value = false
      end
    end
    return @value
  end

  # def length 
  #   return children.length - (children.last.class == ModifierNode ? 1 : 0)
  # end    
end

class ParenthesizedNode < GeneratorNode
  def value
    subsequence.value
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
  def value
    if not @value then
      @value = @children.collect{|child| child.value} if not @value 
    end
    return @value
  end
  
  def single_value?
    true
  end

  def to_s
    "[#{super}]"
  end
end

class NoteNode < TerminalNode
  def value
    if not @value then
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
    return @value
  end

  # def to_s
  #     "#{text_value}=#@value"
  #   end
end

TWO_THIRDS = 2/3.0

class DurationNode < TerminalNode
  def value
    if not @value
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
    return @value
  end  
end

class VelocityNode < TerminalNode
  def value
    @value = INTENSITY[text_value.downcase] if not @value
    return @value
  end
end

class FloatNode < TerminalNode
  def value
    @value = text_value.to_f if not @value
    return @value
  end
end


class IntNode < TerminalNode
  def value
    @value = text_value.to_i if not @value
    return @value
  end
end


class StringNode < TerminalNode
end


class RubyNode < TerminalNode
  def value
    eval if not @value
    return @value
  end
  
  def eval
    puts 'here text val = ' + script.text_value
    @value = Kernel.eval script.text_value
  end
    # 
    # def next
    #   if next? then 
    #     @start = false
    #     eval @value
    #   else 
    #     nil 
    #   end
    # end  
    # 
end


class SequencingGrammarParser
  
  # define a post-parsing step (compress):
  alias parse_sequence parse
  def parse *args
    compress parse_sequence(*args)
  end
  
  def verbose_parse input
    puts "PARSING: #{input}"
    output = parse input
    puts (output ? 'success' : 'failure')
    print_tree output
    #puts "\n"; print_syntax_tree output
    return output
  end
  
  def compress tree
    return nil if tree.nil?
    # strip off unnecessary container nodes
    while tree.nonterminal? and tree.children.size == 1
      tree = tree.children[0]
    end
    # construct parent-children relationships
    parents = []
    tree.visit(lambda do |node| # enter
      node.parent = parents.last
      parents.push node
    end,
    lambda do |node| # exit
      parents.pop
    end)
    return tree
  end
  
  def print_tree tree
    depth = 0
    tree.visit(lambda do |node|
      depth.times{print '    '}
      puts node.inspect # + " parent:" + node.parent.inspect
      depth += 1
    end,
    lambda do |node| # exit
      depth -= 1
    end)
  end
  
  def print_syntax_tree tree
    depth = 0
    tree.visit_parse_tree(lambda do |node|
      if not node.empty? then
        depth.times{print '    '}
        puts node.inspect # + "  parent:" + node.syntax_parent.inspect
      end
      depth += 1
    end,
    lambda do |node| # exit
      depth -= 1
    end)
  end   
end

# SequencingGrammarParser.new.parse_verbose '(1 2 3)&4 ([C4 G4]:mf:q (C4:f:e | G4:f:s*2)) * 2.5  (1 2 3):(4 5 6)'
# SequencingGrammarParser.new.verbose_parse '(1 2):(3 4)*2 ((1|2 3)*2):(3 4)'

# SequencingGrammarParser.new.verbose_parse '0:1:2:3*4'

# SequencingGrammarParser.new.verbose_parse '1 2'
 