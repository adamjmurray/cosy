module Cosy

  class Context
    
    attr_accessor :sequencer, :symbol_table, 
                  :node, :root, :node_stack,
                  :states, :count_limits, :looped
      
    def initialize(sequencer, symbol_table, node)
      @sequencer = sequencer
      @symbol_table = symbol_table
      @root = @node = node
      @node_stack = []
      @states = Hash.new do |hash,key| hash[key] = {} end
      @count_limits = []
    end
    
    def reset
      @node = @root
      @node_stack.clear
      @states.clear
      # @symbol_table.clear # cannot do this! we restart sequences for
      # chained and foreach behaviors, and they use inherited symbol tables
      # if this really needs to reset, we need some other way to inherit
      # symbol tables without this kind of interference
      @count_limits.clear
      @foreach_sequencers = nil
    end

    def enter(node)
      @node_stack.push(@node)
      @node = node
    end
    
    def exit
      @states.delete(node)
      @node = @node_stack.pop
    end
    
    def mark_visit(node)
      state = @states[node]
      state[:visits] ||= 0
      state[:visits] += 1
    end
    
    def visit_count(node)
      @states[node][:visits] ||= 0
    end
    
    def visited?(node)
      visit_count(node) > 0
    end
    
    def clear_visits(node)
      @states[node].delete(:visits)
    end
    
    def create_count_limit(node,limit)
      @count_limits.unshift([node,0,limit])
      mark_visit(node)
    end
    
    # Return true if it's ok to output the current value
    # otherwise exit up to the node whose limit has been exceeded and return false
    def increment_count
      node_exceeded_limit = nil
      #puts @count_limits.inspect
      @count_limits.map! do |node,count,limit| 
        if count >= limit
          node_exceeded_limit = node
          break
        else 
          # increment the count
          [node,count+1,limit]
        end
      end   
      if node_exceeded_limit
        # remove all count limits at or below the one that was exceeded
        loop do
          n,c,l = @count_limits.shift
          break if n.nil? or n==node_exceeded_limit
        end
        # and traverse back up the tree until we get to the node imposing the limit
        loop do
          self.exit
          break if @node.nil? or @node==node_exceeded_limit
        end
        # Now we're at the modified node that imposed the count limit.
        # To get to the proper state we need to exit one more time.
        # We'll leave it to the Sequencer to do the final exit because
        # it seems more consistent with the rest of the Sequencer logic.
        return false
      else
        return true
      end
    end
    # 
    # def start_foreach(foreach_sequences)
    #   @foreach_sequencers = foreach_sequences.collect do |sequence|              
    #     Sequencer.new(sequence, @symbol_table)
    #   end
    #   @foreach_sequencers.each do |sequencer| 
    #     magic_value = sequencer.next
    #     @symbol_table.push_magic_variable(magic_value)
    #   end
    # end
    # 
    # def next_foreach(index=nil)
    #   return false if not @foreach_sequencers
    #   index ||= @foreach_sequencers.length-1
    #   return false if index < 0
    #   
    #   @symbol_table.pop_magic_variable
    #   sequencer = @foreach_sequencers[index]
    #   magic_value = sequencer.next
    #   if magic_value
    #     @symbol_table.push_magic_variable(magic_value)
    #     return true
    #   elsif advance_foreach(index-1)
    #     sequencer.restart
    #     magic_value = sequencer.next
    #     @symbol_table.push_magic_variable(magic_value) 
    #     return true
    #   else
    #     return false 
    #   end
    # end  
  
    def get_binding
      return binding()
    end
    
  end
  
end