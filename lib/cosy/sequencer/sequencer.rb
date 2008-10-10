cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/..'))
require File.join(cosy_root, 'parser/parser')
require File.join(cosy_root, 'sequencer/sequence_state')

module Cosy

  class Sequencer

    attr_accessor :tree, :parser, :state

    def initialize(sequence, bindings={})
      @bindings = bindings
      if sequence.is_a? Treetop::Runtime::SyntaxNode
        @parser = nil
        @tree = sequence
      else
        # This seems inefficient but we need a local parser so we can retreive parse failure
        # info. Maybe I am worrying too much, but using a class parser would not be thread safe...
        @parser = SequenceParser.new 
        @tree = @parser.parse sequence
      end
      restart
    end

    def restart
      if @state
        @state = @state.reset
      else
        @state = SequenceState.new(@tree) if @tree
      end
    end
    
    def parsed?
      !@tree.nil?
    end

    def next
      # puts "STATE: #@state"
      if @children
        values = Chain.new(@children.collect{|child| child.next})
        values.each_with_index do |value,index|
          if value.nil?
            @children[index].restart
            @child_looped[index] = true
            values[index] = @children[index].next
          end
        end
        if not @child_looped.all?
          return values
        else
          @children = nil
          @chilren_looped = nil
          return exit
        end
        
      elsif @state and @state.within_limits?
        node = @state.sequence

        if node.is_a? AssignmentNode
          name = node.value[0].value # extract the String form the nested VariableNode
          value = node.value[1]
          @bindings[name] = value
          
        elsif node.is_a? VariableNode
          return enter_or_emit(node)
          
        elsif node.is_a? ModifiedNode
          # entering this node already captured the behavior in the state, so
          # we can just go ahead and enter the value
          return enter(node.value)
          
        elsif node.is_a? ChainNode
          if node.value.all?{|child| child.atom? and not child.is_a? VariableNode} then
            value = Chain.new(node.value.collect{|child| child.value})
            value = value[0] if value.length == 1 # unwrap unnecessary arrays
            return emit(value)
          elsif node.value.length == 1
            # handle simple subsequence, like (1 2)*2
            return enter(node.value[0])
          else
            # spawn multiple subsequencers
            # TODO: within_limits? will not work for chains and partial iteration
            # becuase the shortest child will make it fail early (we need to only
            # consider the longest child in that scenario)
            @children = node.value.collect{|child| Sequencer.new(child, @bindings)}
            @child_looped = Array.new(@children.length)
            return self.next
          end

        elsif node.is_a? SequenceNode  
          return enter_or_emit(node.value[@state.index])

        elsif node.is_a? ChoiceNode
          return enter_or_emit(node.value) # node.value makes a choice

        elsif node.atom?
          return emit(node.value)
          
        else
          raise "Unexpected node type #{node.class} (#{node.inspect})"
        end
      end
      return exit
    end

    ##############
    private

    def enter_or_emit(node)
      if node.nil?
        exit
      elsif node.is_a? VariableNode
        variable = @bindings[node.value]
        raise "Undefined variable #{node.value}" if not variable
        enter(variable)
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

end


# s = Cosy::Sequencer.new '(c4*{rand(10)} g3)*10'
# s = Cosy::Sequencer.new '$x = c4:q:mf (f2|g2); $x*2 6 7 8'


# s = Sequencer.new '(1 2):(3 4 5):(6 7 8 9)'
# s = Sequencer.new '((1 2):(3 4 5)):(q e. s)' 
# 
# s = Sequencer.new 'c4:r c4:-r d4:r'
# s = Cosy::Sequencer.new '((0 c4 0 bb3 0 ab3 0 g3)*4):(-s r)'

# s = Cosy::Sequencer.new '(mf:q*2 (1:2 3:4) [e4 g4])*4'
# 
#s = Cosy::Sequencer.new '(0 1):(2 3 4) 5' 

# s = Cosy::Sequencer.new '(1 2):(3 4 5):(6 7 8 9)'
# s = Cosy::Sequencer.new '(1 2)*2:(3 4 5):(6 7 8)'
# 
# max = 20
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v.inspect} (#{v.class})"
# end
