require 'sequencing_grammar_parser'
require 'sequence_state'

class Sequencer

  attr_accessor :tree, :parser, :state

  def initialize sequence
    if sequence.is_a? Treetop::Runtime::SyntaxNode
      @parser = nil
      @tree = sequence
    else
      @parser = SequencingGrammarParser.new 
      @tree = @parser.parse sequence
    end
    @state = SequenceState.new(@tree) if @tree
  end

  def restart
    @state = @state.reset
  end

  def next
    # puts "STATE: #@state"
    if within_limits?
      node = @state.sequence
      
      if node.is_a? SequenceNode  
        subseq = node.value[ @state.index]
        if subseq
          if subseq.atom?
            return output(subseq.value)
          else
            return enter(subseq)
          end
        end

      elsif node.is_a? ChainNode
        if node.value.all?{|child| child.atom?} then
          value = node.value.collect{|child| child.value}
          value = value[0] if value.length==1 # unwrap unnecessary arrays
          return output(value)
        elsif node.value.length == 1
          # handle simple subsequence, like (1 2)*2
          return enter(node.value[0])
        else
          puts "TODO: need to handle complex chains"
          # I think we need to spawn multiple subsequencers?
        end

      elsif node.is_a? ChoiceNode
        value = node.value
        if value.atom?
          return output(value.value)
        else
          return enter(value)
        end

      elsif node.terminal? or node.is_a? ChordNode
        return output(node.value)
      end
    end
    return exit
  end
  
  ##############
  private
  
  def within_limits?
    @state and @state.within_limits? 
  end
  
  def output(value)
    @state.increase_count
    @state.advance
    # @stack.each{ |state| state.increase_count }
    return value
  end

  def enter(node)
    @state = @state.enter(node)
    return self.next
  end

  def exit
    if @state
      @state = @state.exit
      if @state
        @state.advance
        return self.next
      end
    end
    return nil
  end
end


# the counting system does not work with this:
# s = Sequencer.new '(1 2)*2'
# max = 20
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v.inspect}"
# end
