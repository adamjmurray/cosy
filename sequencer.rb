require 'sequencing_grammar_parser'
require 'sequence_state'

class Sequencer
  
  attr_accessor :tree, :parser
  
  def initialize sequence
    if sequence.is_a? Treetop::Runtime::SyntaxNode
      @parser = nil
      @tree = sequence
    else
      @parser = SequencingGrammarParser.new 
      @tree = @parser.parse sequence
    end
    restart if @tree
  end
  
  def restart
    @stack = []
    @state = nil
    enter_scope @tree
  end
    
  
  def next
    return nil if not @state
      
    # puts "PRE-ADVANCE STATE: "
    #     @stack.each do |state|
    #       puts "\t#{state}"
    #     end
    #      puts "\t#@state"
    
    if not within_limits?
      if @stack.empty?
        return nil
      else
        exit_scope
        return self.next
      end
    end
    
    # puts "STATE: #@state"
    node = @state.sequence
    index = @state.index
    iteration = @state.iteration
    count = @state.count
    
    if node.is_a? SequenceNode  
      child = node.value[index]
      if child   
        # Need to enter scope for ChainNodes to handle modifiers like repetition
        if child.single_value? and not child.is_a? ChainNode
          return output(child.value)
        else
          enter_scope child
          return self.next
        end
      end 

    elsif node.is_a? ChainNode
      op = node.operator
      if node.single_value? then
        value = node.value
        value = value[0] if value.length == 1
        return output(value)
      elsif node.value.length == 1
        # handle simple subsequence, like (1 2)*2
        enter_scope node.value[0]
        return self.next
      else
        # I think we need to spawn multiple subsequencers?
      end
      return exit_scope
      
    elsif node.single_value?
      return output(node.value)
    end

    return nil
  end
  
  ##############
  private
  
  def within_limits?
    @state.within_limits? and @stack.all?{ |state| state.within_limits? }  
  end
  
  def output(value)
    @state.advance
    @state.increase_count
    @stack.each{ |state| state.increase_count }
    return value
  end

  def enter_scope node
    @stack.push(@state) if @state
    @state = SequenceState.new(node)
     # puts "ENTER #@state"   
  end
  
  def exit_scope
    if @stack.empty?
      nil
    else
      # puts "EXIT #@state"   
      @state = @stack.pop
      @state.advance
    end
  end
end

# the counting system does not work with this:
# s = Sequencer.new '1:2 3:4:5'
# max = 20
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v.inspect}"
# end
