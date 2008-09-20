require 'rubygems'
require 'treetop'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
# Due to a bug? in polyglot/treetop, when requiring this file from a file in another
# folder (like a rake task or test case) it can't find the grammar file unless I add
# this folder to the path:
$: << File.dirname(__FILE__)
require 'grammar'
require File.join(cosy_root, 'constants')

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

  class Chord < Array
  end
  
  class Chain < Array
  end

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
      eval_modifier if not @operand
      return @operand
    end

    def value
      if not @value
        @value = children[0]
      end
      return @value
    end
    
    def length
      1
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

  class BehaviorNode < ContainerNode
  end

  class OperatorNode < TerminalNode
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
        @value += 12*(octave.value+$OCTAVE_OFFSET)
      end
      return @value
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
      @value = Kernel.eval script.text_value
    end
  end


  class Cosy::SequenceParser
    # this class already generated by treetop, but I need to add some behavior

    # define a post-parsing step (compress):
    alias parse_sequence parse
    def parse *args
      compress parse_sequence(*args)
    end

    def verbose_parse input
      puts "PARSING: #{input}"
      output = parse input
      if output
        puts 'success'
        print_tree output
      else
        puts 'failure'
        puts "#{failure_line}:#{failure_column}: #{failure_reason}"
      end
      return output
    end

    def compress tree
      return nil if tree.nil?
      # strip off unnecessary container nodes
      while tree.nonterminal? and tree.children.size == 1
        tree = tree.children[0]
      end
      # construct parent-children relationships
      # is this really necessary? might want it in the future...
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
        puts node.inspect
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
          puts node.inspect
        end
        depth += 1
      end,
      lambda do |node| # exit
        depth -= 1
      end)
    end   
  end

end

# Cosy::SequenceParser.new.verbose_parse '(C4:mf:q D4:q E4:q F4:q)*3 G4:w'


# # TODO: these really need to go into unit tests
# Cosy::SequenceParser.new.verbose_parse 'c4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4)'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4:mf'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4:mf*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4:mf)'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4:mf)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4:(mf f)'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4*2:(mf f)'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4*2:(mf f)*3'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4*2:(mf f)*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4:(mf f)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 g4):(mf f)'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 g4)*2:(mf f)'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 g4):(mf f)*3'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 g4)*2:(mf f)*3'
# puts
# Cosy::SequenceParser.new.verbose_parse '((c4 g4)*2:(mf f)*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4:mf d4)'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4:mf d4)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 d4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 d4*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 d4)'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 d4)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 d4*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 | d4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4)'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 | d4*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4:g3 | d4*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 | d4:a5*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4:g3 | d4)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4:g3 | d4*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4:a5)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4:a5*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 e3 | d4*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 | d4 f5*4'
# puts
# Cosy::SequenceParser.new.verbose_parse 'c4 | (d4 f5)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 e3 | d4)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 e3 | d4*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4 f5)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | (d4 f5))*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | d4 f5*3)*4'
# puts
# Cosy::SequenceParser.new.verbose_parse '(c4 | (d4 f5)*3)*4'
# puts
# # todo choides with chains and sequences (this is getting complicated!)



# puts (Cosy::SequenceParser.new.verbose_parse '-q').value

# x = SequencingGrammarParser.new.verbose_parse '(1 2)*1'
# puts x.length

# SequencingGrammarParser.new.verbose_parse '(1 2 3)&4 ([C4 G4]:mf:q (C4:f:e | G4:f:s*2)) * 2.5  (1 2 3):(4 5 6)'
# SequencingGrammarParser.new.verbose_parse '(1 2):(3 4)*2 ((1|2 3)*2):(3 4)'

# SequencingGrammarParser.new.verbose_parse '0:1:2:3*4'

# SequencingGrammarParser.new.verbose_parse '1 2'
 