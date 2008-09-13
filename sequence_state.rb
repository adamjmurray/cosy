require 'sequencing_grammar_parser'

class SequenceState
  attr_accessor :sequence, :index, :count, :iteration, :count_limit, :iteration_limit
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
  
  def within_limits?
    iteration_within_limits = (@iteration_limit.nil? or @iteration < @iteration_limit)
    count_within_limits = (@count_limit.nil? or @count < @count_limit)
    # The problem with ChainNodes and ChordNodes is their length is the length of the chain
    # even though for simple chains this is really only 1 item...
    # and for complex chains... well who knows?
    # Anyway, it seems I need to introduce a separate sequence_length or something like that
    # We have conflicting definitions of length/size, need to pin this down!
    hack_check = (@index == 0 or (not sequence.is_a? ChainNode and not sequence.is_a? ChordNode))
    return (iteration_within_limits and count_within_limits and hack_check)
  end

  def increase_count
    @count += 1
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
    inspect
  end
end
