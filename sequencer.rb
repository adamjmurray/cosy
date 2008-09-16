require 'sequencing_grammar_parser'
require 'sequence_state'

class Sequencer

  attr_accessor :tree, :parser, :state

  def initialize sequence
    if sequence.is_a? Treetop::Runtime::SyntaxNode
      @parser = nil
      @tree = sequence
    else
      # This seems inefficient but we need a local parser so we can retreive parse failure
      # info. Maybe I am worrying too much, but using a class parser would not be thread safe...
      @parser = SequencingGrammarParser.new 
      @tree = @parser.parse sequence
      if not @tree
        
      end
    end
    @state = SequenceState.new(@tree) if @tree
  end

  def restart
    @state = @state.reset
  end

  def next
    # puts "STATE: #@state"
    if @state and @state.within_limits?
      node = @state.sequence

      if node.is_a? ChainNode
        if node.value.all?{|child| child.atom?} then
          value = node.value.collect{|child| child.value}
          value = value[0] if value.length == 1 # unwrap unnecessary arrays
          return emit(value)
        elsif node.value.length == 1
          # handle simple subsequence, like (1 2)*2
          return enter(node.value[0])
        else
          puts "TODO: need to handle complex chains"
          # I think we need to spawn multiple subsequencers?
        end

      elsif node.is_a? SequenceNode  
        return enter_or_emit(node.value[@state.index])

      elsif node.is_a? ChoiceNode
        return enter_or_emit(node.value) # node.value makes a choice

      elsif node.atom?
        return emit(node.value)
      end
    end
    return exit
  end
  
  ##############
  private
  
  def enter_or_emit(node)
    if node.nil?
      exit
    elsif node.atom?
      emit(node.value)
    else
      enter(node)
    end
  end
  
  def emit(value)
    @state.increase_count
    @state.advance
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


# s = Sequencer.new '1:(2 3)*2'
# max = 20
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v.inspect}"
# end
