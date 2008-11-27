cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/..'))
require File.join(cosy_root, 'parser/parser')
require File.join(cosy_root, 'sequencer/symbol_table')
require File.join(cosy_root, 'sequencer/context')

module Cosy

  # A Sequencer traverses a Cosy sequence and emits values one at a time.
  class Sequencer

    attr_accessor :parser, :sequence, :context

    def initialize(sequence, symbol_table=SymbolTable.new)
      # Careful! Passing in a symbol_table is probably
      # going to cause conflicts in the magic variable stack
      # in some nested foreach situations
      # TODO: test this case, and create a copy of the symbol
      # table if needed
      
      if sequence.is_a? SequencingNode
        @parser = nil
        @sequence = sequence
      else
        # we need a local parser so we can retreive parse failure info
        @parser = SequenceParser.new 
        @sequence = @parser.parse(sequence)
      end
      @context = Context.new(self, symbol_table, @sequence)
    end
    
    # Indicates whether the sequence has parsed succesfully.
    def parsed?
      not @sequence.nil?
    end

    # Restart the sequence from the beginning.
    def restart  
      @context.reset
      end_chain
    end

    # Get the next value in the sequence, or nil if the end of
    # the sequence has been reached.
    def next
      loop do
        if not @chained_sequencers
          node = @context.node
          puts "Sequencing: #{node.inspect}" if $DEBUG_LEVEL and $DEBUG_LEVEL > 0
          case node
          when nil 
            return nil # nothing left to do

          when ChainNode
            begin_chain(node)
            next
            
          when ParallelNode
            sequencers = node.children.collect do |subsequence|
              Sequencer.new(subsequence, @context.symbol_table)
            end
            @context.exit
            return ParallelSequencer.new(sequencers)
                        
          else
            result = node.evaluate(@context)
            puts "Evaluated: #{result}" if $DEBUG_LEVEL and $DEBUG_LEVEL > 5
            case result  
            when SequencingNode
              @context.enter(result)
              next
            when nil
              @context.exit    
              next
            else
              # we have a value to return, unless we've exceeded a count limit
              if context.increment_count
                @context.exit
                return result
              else
                @context.exit # must occur *after* a failed context.increment_count
                next
              end
            end
          end
          
        else # chained_sequencers
          chain = next_chain
          if not @chain_end.all? and context.increment_count
            return chain
          else
            end_chain
            @context.exit
            next
          end
        end
      end
    end
    
    ##############
    private
    
    def begin_chain(node)
      @chained_sequencers = node.children.collect do |subsequence|
        Sequencer.new(subsequence, @context.symbol_table)
      end
      @chain_end = Array.new(@chained_sequencers.length)
    end
    
    def end_chain
      @chained_sequencers = nil
      @chain_end = nil
    end
    
    # Get the next chain value when a chained sequence is occurring.
    def next_chain
      chain = Chain.new(@chained_sequencers.collect{|seq| seq.next})
      chain.each_with_index do |value,index|
        if value.nil?
          @chained_sequencers[index].restart
          @chain_end[index] = true
          chain[index] = @chained_sequencers[index].next
        end
      end
      return chain
    end
  end
  
  class ParallelSequencer < Array
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

# s = Cosy::Sequencer.new '(-1 -2)@((3 4)@($$ $ 99))'
# s = Cosy::Sequencer.new '0 (1 2)@($ 9) 0'
# 
# # s = Cosy::Sequencer.new '(C4 B3 A3 (G3 | B3))@(($ D4 E4)*4)'
#



#s = Cosy::Sequencer.new '(5 6 ((1 2)*2 [3 4])&6)&19'
#s = Cosy::Sequencer.new 'c (1 2)&3 e'

#s = Cosy::Sequencer.new '$x=c d $y; $y=a b; [6 7] $x*2 g'
#s = Cosy::Sequencer.new '1 2 3 4 {{if visit_count(node.parent)==5 then clear_visits(node.parent); node.parent.children.reverse! end}}'


# s = Cosy::Sequencer.new '((2 3 4)&5:(1 0))&8 c'
# s = Cosy::Sequencer.new '(2 3 4)&5:(1 0)&8 c' # subtle difference, worth documenting!

# s = Cosy::Sequencer.new '(c e)@(2 3)@(4 $ $$ 5)'
# 
# s = Cosy::Sequencer.new 'c:ei d e'
# 
# 
#    
# max = 100
# while v=s.next and max > 0
#   max -= 1
#   puts "==> #{v.inspect}"
# end
