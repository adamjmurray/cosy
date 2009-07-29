module Cosy

  # The Cosy Interpreter traverses a Cosy syntax tree and emits states one at a time.
  class Interpreter

    attr_accessor :sequence, :context

    def initialize(sequence, symbol_table=SymbolTable.new)
      # Careful! Passing in a symbol_table is probably
      # going to cause conflicts in the magic variable stack
      # in some nested foreach situations
      # TODO: test this case, and create a copy of the symbol
      # table if needed
      
      if sequence.is_a? SequencingNode
        @sequence = sequence
      else
        @@parser = SequenceParser.new if not defined? @@parser
        @sequence = @@parser.parse(sequence)
      end
      @context = Context.new(self, symbol_table, @sequence)
    end
    
    def input
      @sequence
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
    def next_atom
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
            interpreters = node.children.collect do |subsequence|
              Interpreter.new(subsequence, @context.symbol_table)
            end
            @context.exit
            return ParallelInterpreter.new(interpreters)
                        
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
    
    alias next next_atom
    
    ##############
    private
    
    def begin_chain(node)
      @chained_sequencers = node.children.collect do |subsequence|
        Interpreter.new(subsequence, @context.symbol_table)
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
  
  class ParallelInterpreter < Array
  end
    
end
