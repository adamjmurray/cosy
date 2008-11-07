cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(cosy_root, 'model/values')

class Treetop::Runtime::SyntaxNode

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
    text_value.strip.length == 0 
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
    clazz = self.class.to_s.split('::').last
    "#{clazz} '#{text_value.strip}'"
  end

  def atom?
    false
  end
end


module Cosy

  class SequencingNode < Treetop::Runtime::SyntaxNode
  end

  class TerminalNode < SequencingNode
    def nonterminal?
      false
    end
    def terminal?
      true
    end
    def atom?
      true
    end
  end

  class ContainerNode < SequencingNode   
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
  end
  
  
  class CosyNode < SequenceNode
  end
  
  
  class AssignmentNode < ContainerNode
    # the left hand side of the assignment
    def lhs
      children[0]
    end
    
    # the right hand side of the assignment
    def rhs
      children[1]
    end
    
    def is_variable?
      lhs.is_a? VariableNode
    end
    
    def value
      case lhs
      when TempoNode then Tempo.new(rhs.value)
      when ProgramNode then Program.new(rhs.value)
      else rhs
      end
    end
    
    def length
      1
    end
  end
  
  
  class ChoiceNode < ContainerNode
    def length
      1
    end
    def value
      children[rand(children.length)]
    end
  end
  

  class ModifiedNode < ContainerNode
    def operator
      eval_modifier if not @operator
      return @operator
    end

    def operand
      eval_modifier # can't cache this in case it's Ruby code...
      return @operand
    end

    def value
      # children[0] is the subsequence being modified
      @value = children[0] if not @value
      return @value
    end
    
    def length
      1 # this node has nothing to iterate over, need to descend to its value
    end

    ##########
    private

    def eval_modifier
      if not modifier.empty?
        @operator = modifier.operator.value
        @operand = modifier.operand.value
      else
        @operator = ''
        @operand = 1
      end
    end
  end
  
  
  class ChainNode < ContainerNode
    def value
      if not @value
        @value = Chain.new(@children)
      end
      return @value
    end
    
    def length
      1
      # this might need to be put into a different method?
      # doesn't work with current sequencing logic
      # if not @length 
      #       @length = (value.max{|a,b| a.length<=>b.length}).length
      #     end
      #     return @length
    end
  end
  
  
  class ForEachNode < ContainerNode
    def length
      1
      # This is confusing, but the way foreach is handled inside a
      # sequence_state requires this node be treated as a single element.
      # It's the nested subsequence that actually has a length
    end
  end
  

  class BehaviorNode < ContainerNode
  end


  class OperatorNode < TerminalNode
  end


  class VariableNode < TerminalNode
  end

  
  class ChordNode < ContainerNode 
    def value
      # don't want to cache, so we can re-eval ruby
      # if not @value then
      #   @value = Chord.new(@children.collect{|child| child.value})
      # end
      #  return @value
      # But maybe it would be better to do what chain node does, and require
      # the sequencer to evaluate!
      Chord.new(@children.collect{|child| child.value})
    end

    def length
      1 # even though there could be multiple children, this node is atomic
    end

    def atom?
      true
    end
  end
  

  class PitchNode < TerminalNode
    def value
      if not @value then
        pitch_class_value = PITCH_CLASS[note_name.text_value.upcase]
        accidental_value = 0
        accidentals.text_value.each_byte do |byte|
          case byte.chr
          when '#' then accidental_value += 1
          when 'b' then accidental_value -= 1
          when '+' then accidental_value += 0.5
          when '_' then accidental_value -= 0.5 
          end
        end
        octave_value = 12*(octave.value+$OCTAVE_OFFSET) if not octave.text_value.empty?
        @value = Pitch.new(pitch_class_value, accidental_value, octave_value, text_value)
      end
      return @value
    end
  end
  
  
  class NumericPitchNode < PitchNode
    def value
      if not @value
        @value = Pitch.new(number.value, 0, 0, number.text_value)
      end
    end
  end


  class DurationNode < TerminalNode
    def value
      if not @value
        @value = DURATION[metrical_duration.text_value.downcase]
        if multiplier.text_value != ''
          if multiplier.text_value == '-'
            @value *= -1
          else
            @value *= multiplier.value
          end
        end
        modifier.text_value.each_byte do |byte|
          case byte.chr
          when 't'
            @value *= TWO_THIRDS
          when '.'
            @value *= 1.5
          end
        end
      end
      return Duration.new(@value, text_value)
    end  
  end
  
  
  class NumericDurationNode < DurationNode
    def value
      if not @value
        @value = Duration.new(number.value, number.text_value)
      end
      return @value
    end
  end


  class VelocityNode < TerminalNode
    def value
      @value = INTENSITY[text_value.downcase] if not @value
      return Velocity.new(@value, text_value)
    end
  end

  
  class NumericVelocityNode < TerminalNode
    def value
      if not @value
        @value = Velocity.new(number.value, number.text_value)
      end
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


  class RatioNode < TerminalNode
    def value
      if not @value
        ints = text_value.split("/").map{|s|s.to_i}
        @value = ints[0].to_f / ints[1]
      end
      return @value
    end
  end


  class StringNode < TerminalNode
    def value
      if not @value
        # strip off the surrounding quotes
        @value = text_value[1...-1] 
        # and unescape
        case text_value[0].chr
        when '"' then @value.gsub!('\"', '"')
        when "'" then @value.gsub!("\\'", "'")
        end
      end
      return @value
    end
  end

  
  class TempoNode < TerminalNode
  end

  
  class ProgramNode < TerminalNode
  end
  

  class RubyNode < TerminalNode
    def value(binding=nil)
      eval(script.text_value, binding)
    end
  end
  # NOTE: if I ever introduce other things that eval, make sure
  # to override them and raise in error for the online version


  class CommandNode < TerminalNode
    def value(binding=nil)
      ruby.value(binding)
    end
  end

end
