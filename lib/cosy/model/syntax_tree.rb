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
    @children ||= []
  end

  def value
    @value ||= text_value.strip
  end

  def empty?
    text_value.strip.length == 0 
  end

  def length
    @length ||= (empty? ? 0 : 1)
  end
  alias size length

  def to_s
    text_value
  end

  def inspect
    "#{clazz} '#{text_value}'"
  end
  
  def clazz
    self.class.to_s.split('::').last
  end

  def atom?
    false
  end
end


module Cosy
  
  # The base class for Cosy sequencing nodes
  # TODO: rename to CosyNode and rename existing CosyNode to StatementNode
  class SequencingNode < Treetop::Runtime::SyntaxNode
    
    # Evaluate the current node under the given context.
    # evaluate() should do one of 3 things:
    #   1. return a value, if applicable (if the node is an atomic value)
    #   2. return the next node below this node to evaluate
    #   3. return nil if there are no more nodes below this node
    def evaluate(context)
      raise "Unsupported Operation for #{clazz}"
    end
   
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
    
    def evaluate(context)
      return value(context)
    end
    
  end


  class ContainerNode < SequencingNode   

    def children
      if not @children
        #puts "getting children for #{self.inspect}"
        @children = []
        visit_parse_tree(lambda do |node|
          #puts node.inspect
          if node != self and node.is_a? SequencingNode and (node.atom? or node.terminal? or node.children.size > 1) then
            @children << node
            return false
          end
          # else keep descending:
          return true 
        end)
      end
      return @children
    end

    def length
      children.length
    end

    def [](index)
      children[index]
    end

  end
  
  
  class SequenceNode < ContainerNode
    def evaluate(context) 
      index = context.visit_count(self)
      if index < length
        context.mark_visit(self)
        return children[index]
      else
        return nil
      end
    end
  end
  
  
  class ParallelNode < ContainerNode
  end
  
  
  class CosyNode < SequenceNode
  end
  
  
  class AssignmentNode < ContainerNode
    # the left hand side of the assignment
    def lhs
      children[0]
    end
    
    # the right hand side of the assignment
    def rhs
      children[1]
    end

    def evaluate(context)
      name = lhs.value
      context.symbol_table[name] = rhs
      return nil
    end
  end
  
  
  class ChoiceNode < ContainerNode
    def evaluate(context) 
      if context.visited?(self)
        return nil
      else
        context.mark_visit(self)
        return children[rand(children.length)]
      end
    end
  end
  

  class ModifiedNode < ContainerNode
    def operator
      if not @operator
        if not modifier.empty?
          @operator = modifier.operator.text_value
        else
          @operator = ''
        end
      end
      return @operator
    end

    def operand(context)
      # can't cache this in case its a RubyNode
      if not modifier.empty?
        return modifier.operand.value(context)
      else
        return 1
      end
    end
    
    def evaluate(context)
      # TODO: split repetition and count limit into different classes
      if operator == OP_COUNT_LIMIT
        if not context.visited?(self)
          context.create_count_limit(self,operand(context))
        end
        return children.first

      else
        iteration = context.visit_count(self)
        limit = iteration_limit(context) 
        if not limit or iteration < limit
          subsequence = children.first
          if limit.is_a? Float and limit.to_i==iteration
            # create a count limit to impose a partial iteration on the final iteration
            partial_iteration = limit - limit.to_i
            count_limit = (partial_iteration * subsequence.length).round
            return nil if count_limit < 1 # the limit is already reached
            context.create_count_limit(self,count_limit)
          end
          context.mark_visit(self)
          return subsequence
        else
          return nil
        end
      end
    end
    
    #######
    private

    def iteration_limit(context)
      state = context.states[self]
      limit = state[:iter_limit]
      if not limit
        if operator == OP_ITER_LIMIT
          limit = operand(context)
        end
        state[:iter_limit] = limit
      end
      return limit
    end
    
  end
  
  
  class ChainNode < ContainerNode
  end
  
  
  class ForEachNode < ContainerNode
    def evaluate(context)
      if context.visited? self
        if next_foreach(context)
          return children[-1]
        else
          return nil
        end
      else
        context.mark_visit(self)
        start_foreach(context)
        return children[-1]
      end
    end
    
    ###########
    private
    
    def start_foreach(context)
      symbol_table = context.symbol_table
      state = context.states[self]
      # TODO? should chains work this way too?
      
      foreach_sequencers = children[0...-1].collect do |sequence|              
        Sequencer.new(sequence, symbol_table)
      end
      foreach_sequencers.each do |sequencer| 
        magic_value = sequencer.next
        symbol_table.push_magic_variable(magic_value)
      end
      state[:foreach] = foreach_sequencers
    end
    
    def next_foreach(context)
      state = context.states[self]      
      
      foreach_sequencers = state[:foreach]
      return false if not foreach_sequencers
      
      symbol_table = context.symbol_table
      index = foreach_sequencers.length-1
      
      return evaluate_magic_variables(foreach_sequencers, symbol_table, index)
    end
    
    def evaluate_magic_variables(sequencers, symbol_table, index)  
      return false if index < 0
      symbol_table.pop_magic_variable
      sequencer = sequencers[index]
      magic_value = sequencer.next
      if magic_value
        symbol_table.push_magic_variable(magic_value)
        return true
      elsif evaluate_magic_variables(sequencers, symbol_table, index-1)
        sequencer.restart
        magic_value = sequencer.next
        symbol_table.push_magic_variable(magic_value) 
        return true
      else
        return false 
      end
    end
  end
  

  class BehaviorNode < ContainerNode
  end


  class OperatorNode < TerminalNode
  end
  
  
  class RepetitionNode < BehaviorNode
  end
  
  
  class LimitCountNode < BehaviorNode
  end


  class VariableNode < TerminalNode
    def evaluate(context)
      if context.visited?(self)
        return nil
      else
        context.mark_visit(self)
        sequence = context.symbol_table.lookup(value)
        if sequence
          return sequence
        else
          STDERR.puts "Undefined variable: #{name}"
          # TODO return some special undefined variable error type
          # so it can be handled by the sequencer
          return nil  
        end
      end
    end
  end

  
  class ChordNode < ContainerNode 
    def atom?
      true
    end
    def value(context=nil)
      Chord.new(@children.collect{|child| child.value(context)})
    end
    def evaluate(context=nil)
      return value(context)
    end  
  end
  

  class PitchNode < TerminalNode
    def value(context=nil)
      if not @value then
        octave_value = octave.value if not octave.text_value.empty?
        value = Pitch.new(note_name.text_value, accidentals.text_value, octave_value)
        if not octave_value
          # can't cache pitches with implicit octave
          return value
        end
        @value = value
      end
      return @value
    end
  end
  
  
  class NumericPitchNode < PitchNode
    def value(context=nil)
      if not @value
        value = Pitch.new(number.value(context))
        if number.is_a? RubyNode
          # don't cache, allow re-evaluation
          return value
        end
        @value = value
      end
      return @value
    end
  end
  
  
  class IntervalNode < TerminalNode
    def value(context=nil)
      if not @value
        deg = degree.text_value.to_i
        deg *= -1 if sign.text_value=='-'
        @value = Interval.new(quality.text_value, deg)
      end
      return @value
    end
  end
  
  
  class NumericIntervalNode < IntervalNode
    def value(context=nil)
      if not @value
        value = Interval.new(number.value(context))
        if number.is_a? RubyNode
          # don't cache, allow re-evaluation
          return value
        end
        @value = value
      end
      return @value
    end
  end


  class DurationNode < TerminalNode
    def value(context=nil)
      if not @value
        if multiplier.text_value.empty?
          mult = 1
        elsif multiplier.text_value == '-'
          mult = -1
        else
          mult = multiplier.value
        end
        @value = Duration.new(mult, metrical_duration.text_value, modifier.text_value)
      end
      return @value
    end  
  end
  
  
  class NumericDurationNode < DurationNode
    def value(context=nil)
      if not @value
        value = Duration.new(number.value(context))
        if number.is_a? RubyNode
          # don't cache, allow re-evaluation
          return value
        end
        @value = value
      end
      return @value
    end
  end


  class VelocityNode < TerminalNode
    def value(context=nil)
      if not @value
        @value = Velocity.new(text_value)
      end
      return @value
    end
  end

  
  class NumericVelocityNode < TerminalNode
    def value(context=nil)
      if not @value
        value = Velocity.new(number.value(context))
        if number.is_a? RubyNode
          # don't cache, allow re-evaluation
          return value
        end
        @value = value
      end
      return @value
    end    
  end


  class FloatNode < TerminalNode
    def value(context=nil)
      @value = text_value.to_f if not @value
      return @value
    end
  end


  class IntNode < TerminalNode
    def value(context=nil)
      @value = text_value.to_i if not @value
      return @value
    end
  end


  class RatioNode < TerminalNode
    def value(context=nil)
      if not @value
        ints = text_value.split("/").map{|s|s.to_i}
        @value = ints[0].to_f / ints[1]
      end
      return @value
    end
  end


  class StringNode < TerminalNode
    def value(context=nil)
      if not @value
        # strip off the surrounding quotes
        @value = text_value[1...-1] 
        # and unescape
        case text_value[0].chr
        when '"' then @value.gsub!('\"', '"')
        when "'" then @value.gsub!("\\'", "'")
        end
      end
      return @value
    end
  end
  
  
  class LabelNode < TerminalNode
    def value(context=nil)
      if not @value
        @value = Label.new(text_value[1..-1])
      end
      return @value
    end
  end
  

  class RubyNode < TerminalNode
    def value(context=nil)
      if context
        eval(script.text_value, context.get_binding)
      else
        eval(script.text_value)
      end
    end
  end
  # NOTE: if I ever introduce other things that eval, make sure
  # to override them and raise in error for the online version


  class CommandNode < RubyNode
    def atom?
      false
    end    
    def value(context=nil)
      super
      return nil
    end
  end
  
  
  class OscAddressNode < TerminalNode
    def value(context=nil)
      return OscAddress.new(text_value)
    end
  end

end
