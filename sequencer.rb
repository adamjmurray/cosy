require 'sequencing_grammar_parser'

class Sequencer
  
  attr_accessor :tree, :parser
  
  def initialize sequence
    if sequence.is_a? SyntaxNode
      @parser = nil
      @tree = sequence
    else
      @parser = SequencingGrammarParser.new 
      @tree = @parser.parse sequence
    end
    restart
  end
  
  def restart
    @current = @tree
    @index = 0
    @iteration = 0
    @count = 0
    @max_count = nil
    if @current.is_a? ChainNode and @current.operator == '&'
      @max_count = @current.operand
    end
    @stack = []
  end
  
  def next
    if not @current
      if @stack.empty?
        return nil
      else
        return exit_scope
      end
    end
    node = @current
   #puts "#{@current.inspect}  [#{@index} #{@iteration} #{@count} #{@max_count}]"

    if node.is_a? SequenceNode  
      child = node.value[@index] # % node.length]
      if child
        
        if not @max_count or @count < @max_count
          @index += 1
          @count += 1
          if child.single_value?
            return child.value
          else
            return enter_scope(child)
          end
        end
      else
        return exit_scope
      end 

    elsif node.is_a? ChainNode
      op = node.operator
      if node.single_value? then
        value = node.value[0]
        if not chain_node_done?
          @iteration += 1
          @count += 1
          return value 
        end
      elsif node.value.length == 1 and not chain_node_done?
        @iteration += 1
        return enter_scope(node.value[0])        
      else
        # I think we need to spawn multiple subsequencers?
      end
      return exit_scope
      
    elsif node.single_value?
      @current = nil
      return node.value
    end

    return nil
  end
  
  def chain_node_done?
    node = @current
    operator,operand = node.operator,node.operand
    case operator
    when '*'
      return @iteration >= operand
    when '&'
      return @count >= operand
    end
  end

  def enter_scope node
  # puts "ENTER   [#{@index} #{@iteration} #{@count}]"          
    @stack.push [@current,@index,@iteration]
    @current = node
    @index = 0
    @iteration = 0
  #  @count = 0
    if node.is_a? ChainNode and node.operator == '&'
      @max_count = node.operand.value
    end
    self.next
  end
  
  def exit_scope
    if @stack.empty?
      nil
    else
     # puts 'EXIT'
      lower_count = @count
      @current,@index,@iteration = @stack.pop
     # @count += lower_count
      self.next
    end
  end
end


# s = Sequencer.new '(1 2)*2'
# max = 20
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v}"
# end
