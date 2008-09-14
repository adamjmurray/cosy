require 'sequencing_grammar_parser'

class SequenceState
  attr_accessor :sequence, :index, :count, :iteration, :count_limit, :iteration_limit, :child, :parent
  
  def initialize sequence
    @sequence = sequence
    @index = 0
    @count = 0
    @iteration = 0
    @sequence = sequence
    @length = @sequence.length
    @iteration_limit = 1 # the default
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
  
  def enter subsequence
    @child = SequenceState.new(subsequence)
    @child.parent = self
    return @child
  end
  
  def exit
    @parent.child = nil if @parent
    return @parent
  end
  
  def within_limits?(partial_iteration = 0)
    partial_iteration /= @length 
    iteration_within_limits = (@iteration_limit.nil? or 
                               @iteration+partial_iteration < @iteration_limit)
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
