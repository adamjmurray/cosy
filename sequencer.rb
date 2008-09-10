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
#    puts "#{@current.inspect}  [#{@index} #{@iteration} #{@count}]"

    if node.is_a? SequenceNode  
      child = node.value[@index] # % node.length]
      if child
        @index += 1
        if child.single_value?
          return child.value
        else
          return enter_scope(child)
        end
      else
        return exit_scope
      end 

    elsif node.is_a? ChainNode
      if node.single_value? then
        value = node.value[@index]
        if value and @iteration < node.operand
          @index += 1 
          return value 
        else
          @iteration += 1
          if @iteration < node.operand
            @index = 0
            return self.next
          end
        end
      elsif node.value.length == 1 and @iteration < node.operand
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

  def enter_scope node
   # puts "ENTER   [#{@index} #{@iteration} #{@count}]"          
    @stack.push [@current,@index,@iteration,@count]
    @current = node
    @index = 0
    @iteration = 0
    self.next
  end
  
  def exit_scope
    if @stack.empty?
      nil
    else
     # puts 'EXIT'
      @current,@index,@iteration,@count = @stack.pop
      self.next
    end
  end
end


# s = Sequencer.new '(1 (2 3)*2)*2'
# max = 20
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v}"
# end
