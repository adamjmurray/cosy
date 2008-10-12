cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/..'))
require File.join(cosy_root, 'parser/parser')
require File.join(cosy_root, 'sequencer/symbol_table')

module Cosy

  class SequenceState

    attr_accessor :sequence, :index, :count, :iteration, 
                  :count_limit, :iteration_limit, :children, :parent,
                  :symbol_table

    def initialize(sequence, symbol_table=SymbolTable.new, parent=nil)
      @sequence = sequence
      @symbol_table = symbol_table
      @parent = parent
      
      if sequence.is_a? ForEachNode
        @foreach = sequence.children[0...-1].collect do |subsequence|
          Sequencer.new(subsequence, symbol_table)
        end
        @foreach.each do |sequencer| 
          # not sure about wrapping in a Value... but I need some way to
          # know what type of data I am dealing iwth in Sequener.enter_or_emit
          # because normal variables are actually SequenceNodes
          # Maybe this should be wrapped in a SequenceNode too
          @symbol_table.push_magic_variable Value.new(sequencer.next)
        end
        @sequence = sequence.children[-1]        
      end
      
      @index = 0
      @count = 0
      @iteration = 0
      @length = @sequence.length
      @iteration_limit = 1 # the default
      if defined? @sequence.operator
        case @sequence.operator
        when OP_COUNT_LIMIT
          @count_limit = @sequence.operand
          @iteration_limit = nil
        when OP_ITER_LIMIT
          @iteration_limit = @sequence.operand  
        end
      end

    end

    def reset
      # unwind state to the top
      top = self
      while top.parent
        top = top.parent 
        top.children = nil
      end
      # and reset to default state
      top.index = 0
      top.count = 0
      top.iteration = 0
      return top
    end

    def enter(node)
      @children = [ SequenceState.new(node,@symbol_table,self) ]
      return @children[0]
    end

    def enter_chain(nodes)
      @children = nodes.map{|node| SequenceState.new(node,@symbol_table,self)}
    end

    def exit
      if advance_foreach  
         # the sequencer is going to advance after an exit, so compensate
         # This seems messy, should this advance_foreach be happening somewhere else?
        @index = -1
        @count = 0
        @iteration = 0
        return self 
      end
      @parent.remove_child(self) if @parent
      return @parent
    end
    
    def advance_foreach(index=nil)
      return false if not @foreach
      index ||= @foreach.length-1
      return false if index < 0
      
      symbol_table.pop_magic_variable
      sequencer = @foreach[index]
      magic_value = sequencer.next
      if magic_value
        @symbol_table.push_magic_variable Value.new(magic_value)
        return true
      elsif advance_foreach(index-1)
        sequencer.restart
        @symbol_table.push_magic_variable Value.new(sequencer.next) 
        return true
      else
        return false 
      end
    end

    def add_child(child)
      (@children ||= []) << child
    end

    def remove_child(child)
      @children.delete child if @children
    end

    def within_limits?(partial_iteration = 0)
      partial_iteration /= @length 
      iteration_within_limits = (@iteration_limit.nil? or @iteration+partial_iteration < @iteration_limit)
      count_within_limits = (@count_limit.nil? or @count < @count_limit)
      parent_within_limits = (@parent.nil? or @parent.within_limits?(@index.to_f/@length))    
      return (iteration_within_limits and count_within_limits and parent_within_limits)
    end

    def increase_count
      @count += 1
      @parent.increase_count if @parent
      return self
    end

    def advance
      @index += 1
      if @index >= @length
        @iteration += 1
        @index = 0
      end
    end

    def to_s
      s = "#{@sequence.inspect} : {idx=#@index,count=#@count,iter=#@iteration,len=#@length"
      s += ",iterlim=#@iteration_limit" if @iteration_limit
      s += ",countlim=#@count_limit" if @count_limit
      s += '}'
    end
  end

end
