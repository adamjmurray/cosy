qesl_root = File.expand_path(File.join(File.dirname(__FILE__), '/..'))
require File.join(qesl_root, 'parser/qesl_parser')

module Qesl

  class SequenceState

    attr_accessor :sequence, :index, :count, :iteration, 
                  :count_limit, :iteration_limit, :children, :parent

    def initialize(sequence, parent=nil)
      @sequence = sequence
      @index = 0
      @count = 0
      @iteration = 0
      @sequence = sequence
      @length = sequence.length
      @iteration_limit = 1 # the default
      @parent = parent
      if defined? sequence.operator
        case sequence.operator
        when OP_COUNT_LIMIT
          @count_limit = sequence.operand
          @iteration_limit = nil
        when OP_ITER_LIMIT
          @iteration_limit = sequence.operand  
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
      @children = [ SequenceState.new(node,self) ]
      return @children[0]
    end

    def enter_chain(nodes)
      @children = nodes.map{|node| SequenceState.new(node,self)}
    end

    def exit
      @parent.remove_child(self) if @parent
      return @parent
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